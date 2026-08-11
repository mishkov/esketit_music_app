import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';

class JustAudioAudioPlayer implements AudioPlayer {
  final just_audio.AudioPlayer _audioPlayer;
  final Uri? _baseUri;
  List<Track> _queue = const [];

  JustAudioAudioPlayer({just_audio.AudioPlayer? audioPlayer, Uri? baseUri})
    : _audioPlayer = audioPlayer ?? just_audio.AudioPlayer(),
      _baseUri = baseUri;

  @override
  Duration get currentPosition => _audioPlayer.position;

  @override
  int? get currentIndex => _audioPlayer.currentIndex;

  @override
  Stream<bool> get isPlayingStream => _audioPlayer.playingStream;

  @override
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  @override
  Stream<bool> get hasNextTrackStream =>
      _audioPlayer.sequenceStateStream.map((state) {
        final index = state.currentIndex;

        return index != null && index >= 0 && index < state.sequence.length - 1;
      }).distinct();

  @override
  Stream<bool> get hasPreviousTrackStream => _audioPlayer.currentIndexStream
      .map((index) => index != null && index > 0)
      .distinct();

  @override
  Stream<Track?> get currentTrackStream =>
      _audioPlayer.currentIndexStream.map((index) {
        if (index == null || index < 0 || index >= _queue.length) {
          return null;
        }

        return _queue[index];
      });

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

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

    await _audioPlayer.setAudioSources(
      _queue.map(_buildAudioSource).toList(growable: false),
      initialIndex: initialIndex,
    );
    await _audioPlayer.play();
  }

  @override
  Future<void> appendToQueue(List<Track> tracks) async {
    if (tracks.isEmpty) {
      return;
    }

    _queue = List<Track>.unmodifiable([..._queue, ...tracks]);

    await _audioPlayer.addAudioSources(
      tracks.map(_buildAudioSource).toList(growable: false),
    );
  }

  @override
  Future<void> removeTracks(Set<int> trackIds) async {
    if (trackIds.isEmpty) {
      return;
    }
    final indexesToRemove = <int>[
      for (var index = _queue.length - 1; index >= 0; index--)
        if (trackIds.contains(_queue[index].id)) index,
    ];
    for (final index in indexesToRemove) {
      final previousQueue = _queue;
      final updatedQueue = previousQueue.toList()..removeAt(index);
      _queue = List<Track>.unmodifiable(updatedQueue);

      try {
        await _audioPlayer.removeAudioSourceAt(index);
      } catch (_) {
        _queue = previousQueue;
        rethrow;
      }
    }
  }

  @override
  Future<void> removeUpcomingTracks(Set<int> trackIds) async {
    final safeCurrentIndex = currentIndex;
    if (safeCurrentIndex == null || trackIds.isEmpty) {
      return;
    }

    final indexesToRemove = <int>[
      for (var index = _queue.length - 1; index > safeCurrentIndex; index--)
        if (trackIds.contains(_queue[index].id)) index,
    ];
    for (final index in indexesToRemove) {
      final previousQueue = _queue;
      final updatedQueue = previousQueue.toList()..removeAt(index);
      _queue = List<Track>.unmodifiable(updatedQueue);

      try {
        await _audioPlayer.removeAudioSourceAt(index);
      } catch (_) {
        _queue = previousQueue;
        rethrow;
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> skipToNextTrack() async {
    await _audioPlayer.seekToNext();
  }

  @override
  Future<void> skipToPreviousTrack() async {
    await _audioPlayer.seekToPrevious();
  }

  Uri _extractTrackUri(Track track) {
    final file = track.file;
    if (file is LocalFile) {
      if (file.path.isEmpty) {
        throw StateError('Local track file path is empty');
      }

      return Uri.file(file.path);
    }
    if (file is HttpFile) {
      final path = file.uri.toString();
      if (path.isEmpty) {
        throw StateError('Track file path is empty');
      }

      return _resolveTrackUri(path);
    }

    throw StateError('Unsupported track file type: ${file.runtimeType}');
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
    if (image is LocalFile) {
      return image.path.isEmpty ? null : Uri.file(image.path);
    }
    if (image is HttpFile) {
      final imagePath = image.uri.toString();
      if (imagePath.isEmpty) {
        return null;
      }

      return _resolveTrackUri(imagePath);
    }

    return null;
  }

  @override
  Future<void> togglePlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();

      return;
    }
    await _audioPlayer.play();
  }

  just_audio.AudioSource _buildAudioSource(Track track) {
    final uri = _extractTrackUri(track);
    final imageUri = _extractImageUri(track);

    return just_audio.AudioSource.uri(
      uri,
      tag: MediaItem(
        id: uri.toString(),
        album: 'Esketit Music',
        title: track.name,
        artist: track.authors.map((author) => author.currentName).join(', '),
        artUri: imageUri,
      ),
    );
  }
}
