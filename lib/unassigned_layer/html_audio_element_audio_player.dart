import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:web/web.dart';

extension type _MediaSessionActionDetails(JSObject _) implements JSObject {
  external double? get seekTime;
  external double? get seekOffset;
  external bool? get fastSeek;
}

class HtmlAudioElementAudioPlayer implements AudioPlayer {
  static const Duration _metadataLoadTimeout = Duration(seconds: 20);
  static const Duration _positionTickInterval = Duration(milliseconds: 250);

  final HTMLAudioElement _audioElement;
  final Uri? _baseUri;
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<bool> _hasPreviousTrackController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _hasNextTrackController =
      StreamController<bool>.broadcast();
  final List<StreamSubscription<Event>> _subscriptions =
      <StreamSubscription<Event>>[];

  List<Track> _queue = const [];
  int? _currentIndex;
  Timer? _positionTimer;
  int _loadGeneration = 0;

  HtmlAudioElementAudioPlayer({HTMLAudioElement? audioElement, Uri? baseUri})
    : _audioElement = audioElement ?? HTMLAudioElement(),
      _baseUri = baseUri {
    _audioElement.preload = 'auto';
    _bindAudioElementEvents();
    _configureMediaSessionActions();
  }

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Stream<Track?> get currentTrackStream =>
      _streamWithInitial(_currentTrack, _currentTrackController.stream);

  @override
  Stream<Duration?> get durationStream =>
      _streamWithInitial(_duration, _durationController.stream);

  @override
  Stream<bool> get hasNextTrackStream =>
      _streamWithInitial(_hasNextTrack, _hasNextTrackController.stream);

  @override
  Stream<bool> get hasPreviousTrackStream =>
      _streamWithInitial(_hasPreviousTrack, _hasPreviousTrackController.stream);

  @override
  Stream<bool> get isPlayingStream =>
      _streamWithInitial(_isPlaying, _isPlayingController.stream);

  @override
  Stream<Duration> get positionStream =>
      _streamWithInitial(_currentPosition, _positionController.stream);

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {
    if (tracks.isEmpty) {
      throw StateError('Playback queue must not be empty');
    }
    if (initialIndex < 0 || initialIndex >= tracks.length) {
      throw RangeError.index(initialIndex, tracks, 'initialIndex');
    }

    _queue = List<Track>.unmodifiable(tracks);
    _currentIndex = initialIndex;
    _emitCurrentTrack();
    _emitNavigationState();

    await _loadCurrentTrack();
    await _play();
  }

  @override
  Future<void> appendToQueue(List<Track> tracks) async {
    if (tracks.isEmpty) {
      return;
    }

    _queue = List<Track>.unmodifiable([..._queue, ...tracks]);
    _emitNavigationState();
  }

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _audioElement.pause();
    _clearAudioSource();
    _clearMediaSession();
    await _isPlayingController.close();
    await _currentTrackController.close();
    await _positionController.close();
    await _durationController.close();
    await _hasPreviousTrackController.close();
    await _hasNextTrackController.close();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _seekTo(position);
  }

  @override
  Future<void> skipToNextTrack() async {
    final index = _currentIndex;
    if (index == null || index >= _queue.length - 1) {
      return;
    }

    await _skipTo(index + 1, shouldPlay: !_audioElement.paused);
  }

  @override
  Future<void> skipToPreviousTrack() async {
    final index = _currentIndex;
    if (index == null || index <= 0) {
      return;
    }

    await _skipTo(index - 1, shouldPlay: !_audioElement.paused);
  }

  @override
  Future<void> togglePlay() async {
    if (_audioElement.paused) {
      await _play();

      return;
    }

    _audioElement.pause();
  }

  void _bindAudioElementEvents() {
    _subscriptions
      ..add(
        _audioElement.onPlay.listen((_) {
          _emitPlayingState();
          _startPositionTimer();
        }),
      )
      ..add(
        _audioElement.onPlaying.listen((_) {
          _emitPlayingState();
          _startPositionTimer();
        }),
      )
      ..add(
        _audioElement.onPause.listen((_) {
          _emitPlayingState();
          _stopPositionTimer();
        }),
      )
      ..add(
        _audioElement.onEnded.listen((_) {
          _stopPositionTimer();
          unawaited(_playNextAfterCurrentEnds());
        }),
      )
      ..add(
        _audioElement.onTimeUpdate.listen((_) {
          _emitPosition();
          _updateMediaSessionPosition();
        }),
      )
      ..add(
        _audioElement.onLoadedMetadata.listen((_) {
          _emitDuration();
          _updateMediaSessionPosition();
        }),
      )
      ..add(
        _audioElement.onDurationChange.listen((_) {
          _emitDuration();
          _updateMediaSessionPosition();
        }),
      );
  }

  Future<void> _playNextAfterCurrentEnds() async {
    final index = _currentIndex;
    if (index == null || index >= _queue.length - 1) {
      _audioElement.pause();
      _emitPlayingState();
      _emitPosition();
      _setMediaSessionPlaybackState('none');

      return;
    }

    await _skipTo(index + 1, shouldPlay: true);
  }

  Future<void> _skipTo(int index, {required bool shouldPlay}) async {
    _currentIndex = index;
    _emitCurrentTrack();
    _emitNavigationState();
    await _loadCurrentTrack();
    if (shouldPlay) {
      await _play();
    }
  }

  Future<void> _loadCurrentTrack() async {
    final track = _currentTrack;
    if (track == null) {
      _clearAudioSource();
      _emitCurrentTrack();
      _emitDuration();
      _emitPosition();

      return;
    }

    final generation = ++_loadGeneration;
    _audioElement.pause();
    _stopPositionTimer();
    _clearAudioSource();

    final uri = _resolveTrackUri(_extractTrackPath(track));
    _audioElement.src = uri.toString();
    _audioElement.preload = 'auto';
    _audioElement.load();
    _updateMediaSessionMetadata(track);

    await _waitForMetadata(generation, uri);
    _emitDuration();
    _emitPosition();
  }

  Future<void> _waitForMetadata(int generation, Uri uri) async {
    if (_audioElement.readyState >= HTMLMediaElement.HAVE_METADATA) {
      return;
    }

    final completer = Completer<void>();
    late final StreamSubscription<Event> metadataSubscription;
    late final StreamSubscription<Event> canPlaySubscription;
    late final StreamSubscription<Event> errorSubscription;

    void complete() {
      if (!completer.isCompleted && generation == _loadGeneration) {
        completer.complete();
      }
    }

    void completeError() {
      if (!completer.isCompleted && generation == _loadGeneration) {
        completer.completeError(StateError(_audioLoadErrorMessage(uri)));
      }
    }

    metadataSubscription = _audioElement.onLoadedMetadata.listen((_) {
      complete();
    });
    canPlaySubscription = _audioElement.onCanPlay.listen((_) {
      complete();
    });
    errorSubscription = _audioElement.onError.listen((_) {
      completeError();
    });

    try {
      await completer.future.timeout(
        _metadataLoadTimeout,
        onTimeout: () => throw TimeoutException(
          'Timed out while loading audio metadata: $uri',
          _metadataLoadTimeout,
        ),
      );
    } finally {
      await metadataSubscription.cancel();
      await canPlaySubscription.cancel();
      await errorSubscription.cancel();
    }
  }

  Future<void> _play() async {
    if (_currentTrack == null) {
      return;
    }
    if (_audioElement.src.isEmpty) {
      await _loadCurrentTrack();
    }

    await _audioElement.play().toDart;
    _emitPlayingState();
    _startPositionTimer();
  }

  void _seekTo(Duration position) {
    final seconds = position.inMilliseconds / Duration.millisecondsPerSecond;
    final duration = _duration;
    final safeSeconds = duration == null
        ? seconds
        : seconds.clamp(0, duration.inMilliseconds / 1000).toDouble();

    _audioElement.currentTime = safeSeconds;
    _emitPosition();
    _updateMediaSessionPosition();
  }

  void _clearAudioSource() {
    _audioElement.pause();
    _audioElement.removeAttribute('src');
    _audioElement.load();
  }

  void _startPositionTimer() {
    _positionTimer ??= Timer.periodic(_positionTickInterval, (_) {
      _emitPosition();
      _updateMediaSessionPosition();
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _emitPlayingState() {
    final isPlaying = !_audioElement.paused;
    if (!_isPlayingController.isClosed) {
      _isPlayingController.add(isPlaying);
    }
    _setMediaSessionPlaybackState(isPlaying ? 'playing' : 'paused');
  }

  void _emitCurrentTrack() {
    if (!_currentTrackController.isClosed) {
      _currentTrackController.add(_currentTrack);
    }
  }

  void _emitPosition() {
    if (!_positionController.isClosed) {
      _positionController.add(_currentPosition);
    }
  }

  void _emitDuration() {
    if (!_durationController.isClosed) {
      _durationController.add(_duration);
    }
  }

  void _emitNavigationState() {
    if (!_hasPreviousTrackController.isClosed) {
      _hasPreviousTrackController.add(_hasPreviousTrack);
    }
    if (!_hasNextTrackController.isClosed) {
      _hasNextTrackController.add(_hasNextTrack);
    }
  }

  Stream<T> _streamWithInitial<T>(T initialValue, Stream<T> stream) {
    return Stream<T>.multi((controller) {
      controller.add(initialValue);
      final subscription = stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  bool get _isPlaying => !_audioElement.paused;

  bool get _hasPreviousTrack {
    final index = _currentIndex;

    return index != null && index > 0;
  }

  bool get _hasNextTrack {
    final index = _currentIndex;

    return index != null && index >= 0 && index < _queue.length - 1;
  }

  Track? get _currentTrack {
    final index = _currentIndex;
    if (index == null || index < 0 || index >= _queue.length) {
      return null;
    }

    return _queue[index];
  }

  Duration get _currentPosition {
    final seconds = _audioElement.currentTime;
    if (!seconds.isFinite || seconds < 0) {
      return Duration.zero;
    }

    return Duration(milliseconds: (seconds * 1000).round());
  }

  Duration? get _duration {
    final seconds = _audioElement.duration;
    if (!seconds.isFinite || seconds < 0) {
      return null;
    }

    return Duration(milliseconds: (seconds * 1000).round());
  }

  String _extractTrackPath(Track track) {
    final file = track.file;
    if (file is! HttpFile) {
      throw StateError('Track file must be HttpFile');
    }

    final path = file.uri.toString();
    if (path.isEmpty) {
      throw StateError('Track file path is empty');
    }

    return path;
  }

  Uri _resolveTrackUri(String path) {
    final candidate = Uri.tryParse(path);
    if (candidate != null && candidate.hasScheme) {
      return candidate;
    }

    if (_baseUri == null) {
      throw StateError('Relative track path requires baseUri: $path');
    }

    return _baseUri.resolve(path);
  }

  Uri? _extractImageUri(Track track) {
    final image = track.image;
    if (image is! HttpFile) {
      return null;
    }

    final imagePath = image.uri.toString();
    if (imagePath.isEmpty) {
      return null;
    }

    return _resolveTrackUri(imagePath);
  }

  String _audioLoadErrorMessage(Uri uri) {
    final error = _audioElement.error;
    if (error == null) {
      return 'Failed to load audio: $uri';
    }

    return 'Failed to load audio: $uri (${error.code})';
  }

  MediaSession? get _mediaSession {
    final browserNavigator = window.navigator;
    if (!browserNavigator.hasProperty('mediaSession'.toJS).toDart) {
      return null;
    }

    return browserNavigator.mediaSession;
  }

  void _configureMediaSessionActions() {
    _setMediaSessionActionHandler('play', () {
      unawaited(_play());
    });
    _setMediaSessionActionHandler('pause', () {
      _audioElement.pause();
    });
    _setMediaSessionActionHandler('previoustrack', () {
      unawaited(skipToPreviousTrack());
    });
    _setMediaSessionActionHandler('nexttrack', () {
      unawaited(skipToNextTrack());
    });
    _setMediaSessionActionHandler('seekbackward', () {
      _seekTo(_currentPosition - const Duration(seconds: 10));
    });
    _setMediaSessionActionHandler('seekforward', () {
      _seekTo(_currentPosition + const Duration(seconds: 10));
    });

    try {
      _mediaSession?.setActionHandler(
        'seekto',
        ((_MediaSessionActionDetails details) {
          final seekTime = details.seekTime;
          if (seekTime == null || !seekTime.isFinite) {
            return;
          }

          _seekTo(Duration(milliseconds: (seekTime * 1000).round()));
        }).toJS,
      );
    } catch (_) {
      // Browsers are allowed to reject unsupported Media Session actions.
    }
  }

  void _setMediaSessionActionHandler(String action, void Function() handler) {
    try {
      _mediaSession?.setActionHandler(action, handler.toJS);
    } catch (_) {
      // Browsers are allowed to reject unsupported Media Session actions.
    }
  }

  void _updateMediaSessionMetadata(Track track) {
    final imageUri = _extractImageUri(track);
    final artist = track.authors
        .map((author) => author.currentName)
        .where((name) => name.isNotEmpty)
        .join(', ');
    final metadataInit = imageUri == null
        ? MediaMetadataInit(
            title: track.name,
            artist: artist,
            album: 'Esketit Music',
          )
        : MediaMetadataInit(
            title: track.name,
            artist: artist,
            album: 'Esketit Music',
            artwork: <MediaImage>[MediaImage(src: imageUri.toString())].toJS,
          );

    try {
      _mediaSession?.metadata = MediaMetadata(metadataInit);
      _updateMediaSessionPosition();
    } catch (_) {
      // Media Session metadata is progressive enhancement only.
    }
  }

  void _updateMediaSessionPosition() {
    final duration = _duration;
    if (duration == null || duration == Duration.zero) {
      return;
    }

    try {
      _mediaSession?.setPositionState(
        MediaPositionState(
          duration: duration.inMilliseconds / 1000,
          playbackRate: _audioElement.playbackRate,
          position: _currentPosition.inMilliseconds / 1000,
        ),
      );
    } catch (_) {
      // setPositionState is not supported consistently across browsers.
    }
  }

  void _setMediaSessionPlaybackState(String state) {
    try {
      _mediaSession?.playbackState = state;
    } catch (_) {
      // Media Session playback state is progressive enhancement only.
    }
  }

  void _clearMediaSession() {
    final mediaSession = _mediaSession;
    if (mediaSession == null) {
      return;
    }

    try {
      mediaSession.metadata = null;
      mediaSession.playbackState = 'none';
      for (final action in const <String>[
        'play',
        'pause',
        'previoustrack',
        'nexttrack',
        'seekbackward',
        'seekforward',
        'seekto',
      ]) {
        mediaSession.setActionHandler(action, null);
      }
    } catch (_) {
      // Best effort cleanup only.
    }
  }
}
