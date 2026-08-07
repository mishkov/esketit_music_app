import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_collecting.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'play track seeds autoplay session and prefetches continuation',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final autoplayStorage = _FakeAutoplayStorage(
        batches: [
          _batch(
            const AutoplayContext(
              sourceType: AutoplaySourceType.playlist,
              sourceId: 7,
            ),
            [_track(3), _track(4)],
          ),
        ],
      );
      final bloc = _createBloc(
        audioPlayer: audioPlayer,
        autoplayStorage: autoplayStorage,
      );

      bloc.add(
        PlayTrack(
          _track(1),
          queue: [_track(1), _track(2)],
          autoplayContext: const AutoplayContext(
            sourceType: AutoplaySourceType.playlist,
            sourceId: 7,
          ),
        ),
      );
      await _settleBloc();

      expect(bloc.state.selectedTrack?.id, 1);
      expect(audioPlayer.appendedTrackIds, [3, 4]);
      expect(
        autoplayStorage.requests.single.context,
        const AutoplayContext(
          sourceType: AutoplaySourceType.playlist,
          sourceId: 7,
        ),
      );
      expect(autoplayStorage.requests.single.recentTrackIds, [1]);
      expect(autoplayStorage.requests.single.excludedTrackIds, [1, 2]);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'manual selection keeps only the explicitly selected disliked track',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final bloc = _createBloc(audioPlayer: audioPlayer);
      final selectedTrack = _track(2, isDisliked: true);

      bloc.add(
        PlayTrack(
          selectedTrack,
          queue: [
            _track(1, isDisliked: true),
            selectedTrack,
            _track(3, isDisliked: true),
            _track(4, isAvailable: false),
            _track(5),
          ],
        ),
      );
      await _settleBloc();

      expect(audioPlayer.startedTrackIds, [2, 5]);
      expect(audioPlayer.startedInitialIndex, 0);
      expect(bloc.state.selectedTrack?.id, 2);

      await audioPlayer.advanceAutomatically();
      await _settleBloc();

      expect(bloc.state.selectedTrack?.id, 5);

      await _dispose(bloc, audioPlayer);
    },
  );

  test('automatic progression skips a disliked middle track', () async {
    final audioPlayer = _FakeAudioPlayer();
    final bloc = _createBloc(audioPlayer: audioPlayer);

    bloc.add(
      PlayTrack(
        _track(1),
        queue: [_track(1), _track(2, isDisliked: true), _track(3)],
        autoplayContext: const AutoplayContext(
          sourceType: AutoplaySourceType.album,
          sourceId: 8,
        ),
      ),
    );
    await _settleBloc();

    expect(audioPlayer.startedTrackIds, [1, 3]);

    await audioPlayer.advanceAutomatically();
    await _settleBloc();

    expect(bloc.state.selectedTrack?.id, 3);

    await _dispose(bloc, audioPlayer);
  });

  test(
    'arbitrary repeated queue order retains one manual dislike bypass',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final bloc = _createBloc(audioPlayer: audioPlayer);
      final firstRepeatedTrack = _track(7, isDisliked: true);
      final selectedRepeatedTrack = _track(7, isDisliked: true);

      bloc.add(
        PlayTrack(
          selectedRepeatedTrack,
          queue: [
            firstRepeatedTrack,
            _track(9),
            selectedRepeatedTrack,
            _track(7, isDisliked: true),
            _track(10),
          ],
        ),
      );
      await _settleBloc();

      expect(audioPlayer.startedTrackIds, [9, 7, 10]);
      expect(audioPlayer.startedInitialIndex, 1);

      await audioPlayer.advanceAutomatically();
      await _settleBloc();

      expect(bloc.state.selectedTrack?.id, 10);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'persisted dislike of current track cleans queue and advances with analytics',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final analytics = _FakeAnalyticsCollector();
      final bloc = _createBloc(audioPlayer: audioPlayer, analytics: analytics);

      bloc.add(
        PlayTrack(
          _track(1),
          queue: [_track(1), _track(2), _track(1), _track(3)],
        ),
      );
      await _settleBloc();

      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 1,
          isDisliked: true,
          collectDislikeAnalytics: true,
          sourceContext: AutoplayContext(
            sourceType: AutoplaySourceType.album,
            sourceId: 44,
          ),
          sourceQueueIndex: 0,
          sourceWasPlaying: true,
        ),
      );
      await _settleBloc();

      expect(audioPlayer.queueTrackIds, [1, 2, 3]);
      expect(audioPlayer.removedUpcomingTrackIdSets, [
        {1},
      ]);
      expect(bloc.state.selectedTrack?.id, 2);
      expect(audioPlayer.stopCallCount, 0);

      final dislikeEvents = analytics.events
          .where((event) => event.type == AnalyticsEventType.trackDislike)
          .toList();
      expect(dislikeEvents, hasLength(1));
      expect(dislikeEvents.single.trackId, 1);
      expect(dislikeEvents.single.albumId, 44);
      expect(dislikeEvents.single.metadata, {
        'sourceType': 'album',
        'sourceId': 44,
        'queueIndex': 0,
        'wasPlaying': true,
      });

      final skipEvent = analytics.events.singleWhere(
        (event) => event.type == AnalyticsEventType.trackSkip,
      );
      expect(skipEvent.metadata['reason'], 'dislike');
      expect(skipEvent.metadata['nextTrackId'], 2);
      final trackChangeEvent = analytics.events.singleWhere(
        (event) => event.type == AnalyticsEventType.trackChange,
      );
      expect(trackChangeEvent.metadata['reason'], 'dislike');
      expect(trackChangeEvent.metadata['previousTrackId'], 1);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'current dislike advances before blocking autoplay prefetch completes',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      const autoplayContext = AutoplayContext(
        sourceType: AutoplaySourceType.playlist,
        sourceId: 45,
      );
      final autoplayCompleter = Completer<AutoplayTracksBatch>();
      final autoplayStorage = _FakeAutoplayStorage(
        blockingFirstBatch: autoplayCompleter.future,
      );
      final bloc = _createBloc(
        audioPlayer: audioPlayer,
        autoplayStorage: autoplayStorage,
      );
      final selectedTrack = _track(1);

      bloc.add(
        PlayTrack(
          selectedTrack,
          queue: [selectedTrack, _track(2), _track(1), _track(1)],
          autoplayContext: autoplayContext,
        ),
      );
      await _settleBloc();

      expect(autoplayStorage.requests, isEmpty);

      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 1,
          isDisliked: true,
          collectDislikeAnalytics: false,
        ),
      );
      await _settleBloc();

      expect(bloc.state.selectedTrack?.id, 2);
      expect(audioPlayer.queueTrackIds, [1, 2]);
      expect(autoplayStorage.requests, hasLength(1));
      expect(autoplayCompleter.isCompleted, isFalse);

      autoplayCompleter.complete(_batch(autoplayContext, const []));
      await _settleBloc();

      await _dispose(bloc, audioPlayer);
    },
  );

  test('persisted dislike removes every matching future occurrence', () async {
    final audioPlayer = _FakeAudioPlayer();
    final analytics = _FakeAnalyticsCollector();
    final bloc = _createBloc(audioPlayer: audioPlayer, analytics: analytics);

    bloc.add(
      PlayTrack(_track(1), queue: [_track(1), _track(2), _track(3), _track(2)]),
    );
    await _settleBloc();

    bloc.add(
      const PersistedTrackPreferenceChanged(
        trackId: 2,
        isDisliked: true,
        collectDislikeAnalytics: false,
      ),
    );
    await _settleBloc();

    expect(audioPlayer.queueTrackIds, [1, 3]);
    expect(bloc.state.selectedTrack?.id, 1);
    expect(
      analytics.events.where(
        (event) =>
            event.type == AnalyticsEventType.trackDislike ||
            event.type == AnalyticsEventType.trackUndislike,
      ),
      isEmpty,
    );

    bloc.add(
      const PersistedTrackPreferenceChanged(
        trackId: 2,
        isDisliked: false,
        collectDislikeAnalytics: false,
      ),
    );
    await _settleBloc();

    expect(audioPlayer.queueTrackIds, [1, 3]);

    await _dispose(bloc, audioPlayer);
  });

  test('persisted preference overrides stale track response flags', () async {
    final audioPlayer = _FakeAudioPlayer();
    final bloc = _createBloc(audioPlayer: audioPlayer);

    bloc.add(
      const PersistedTrackPreferenceChanged(
        trackId: 2,
        isDisliked: true,
        collectDislikeAnalytics: false,
      ),
    );
    await _settleBloc();
    bloc.add(PlayTrack(_track(1), queue: [_track(1), _track(2), _track(3)]));
    await _settleBloc();

    expect(audioPlayer.startedTrackIds, [1, 3]);

    bloc.add(
      const PersistedTrackPreferenceChanged(
        trackId: 2,
        isDisliked: false,
        collectDislikeAnalytics: false,
      ),
    );
    await _settleBloc();
    bloc.add(
      PlayTrack(
        _track(1),
        queue: [_track(1), _track(2, isDisliked: true), _track(3)],
      ),
    );
    await _settleBloc();

    expect(audioPlayer.startedTrackIds, [1, 2, 3]);

    await _dispose(bloc, audioPlayer);
  });

  test(
    'disliking current track stops when no eligible track remains',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final analytics = _FakeAnalyticsCollector();
      final bloc = _createBloc(audioPlayer: audioPlayer, analytics: analytics);

      bloc.add(
        PlayTrack(
          _track(1),
          queue: [
            _track(1),
            _track(2, isDisliked: true),
            _track(3, isAvailable: false),
          ],
        ),
      );
      await _settleBloc();

      expect(audioPlayer.queueTrackIds, [1]);

      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 1,
          isDisliked: true,
          collectDislikeAnalytics: false,
        ),
      );
      await _settleBloc();

      expect(audioPlayer.stopCallCount, 1);
      expect(bloc.state.isPlaying, isFalse);
      expect(bloc.state.selectedTrack?.id, 1);
      expect(
        analytics.events.where(
          (event) => event.type == AnalyticsEventType.pause,
        ),
        isEmpty,
      );

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'current dislike prefetches after repeated future items are removed',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      const autoplayContext = AutoplayContext(
        sourceType: AutoplaySourceType.playlist,
        sourceId: 19,
      );
      final autoplayStorage = _FakeAutoplayStorage(
        batches: [
          _batch(autoplayContext, [
            _track(9),
            _track(10, isDisliked: true),
            _track(11),
            _track(12),
            _track(13),
          ]),
        ],
      );
      final bloc = _createBloc(
        audioPlayer: audioPlayer,
        autoplayStorage: autoplayStorage,
      );
      final selectedTrack = _track(1);

      bloc.add(
        PlayTrack(
          selectedTrack,
          queue: [selectedTrack, _track(1), _track(1), _track(1), _track(2)],
          autoplayContext: autoplayContext,
        ),
      );
      await _settleBloc();

      expect(autoplayStorage.requests, isEmpty);

      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 1,
          isDisliked: true,
          collectDislikeAnalytics: false,
        ),
      );
      await _settleBloc();

      expect(autoplayStorage.requests, hasLength(1));
      expect(audioPlayer.queueTrackIds, [1, 2, 9, 11, 12, 13]);
      expect(audioPlayer.appendedTrackIds, [9, 11, 12, 13]);
      expect(bloc.state.selectedTrack?.id, 2);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'autoplay start defensively excludes disliked and unavailable tracks',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      const autoplayContext = AutoplayContext.myVibe();
      final autoplayStorage = _FakeAutoplayStorage(
        batches: [
          _batch(autoplayContext, [
            _track(11, isDisliked: true),
            _track(12, isAvailable: false),
            _track(13),
          ]),
        ],
      );
      final bloc = _createBloc(
        audioPlayer: audioPlayer,
        autoplayStorage: autoplayStorage,
      );

      bloc.add(const StartAutoplayPlaybackRequested(autoplayContext));
      await _settleBloc();

      expect(audioPlayer.startedTrackIds, [13]);
      expect(bloc.state.selectedTrack?.id, 13);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'empty eligible autoplay continuation becomes exhausted without a loop',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      const autoplayContext = AutoplayContext(
        sourceType: AutoplaySourceType.track,
        sourceId: 1,
      );
      final autoplayStorage = _FakeAutoplayStorage(
        batches: [
          _batch(autoplayContext, [
            _track(2, isDisliked: true),
            _track(3, isAvailable: false),
          ]),
        ],
      );
      final bloc = _createBloc(
        audioPlayer: audioPlayer,
        autoplayStorage: autoplayStorage,
      );

      bloc.add(PlayTrack(_track(1), autoplayContext: autoplayContext));
      await _settleBloc();

      bloc
        ..add(const SkipToNextTrackRequested())
        ..add(const SkipToNextTrackRequested());
      await _settleBloc();

      expect(autoplayStorage.requests, hasLength(1));
      expect(audioPlayer.appendedTrackIds, isEmpty);
      expect(audioPlayer.queueTrackIds, [1]);

      await _dispose(bloc, audioPlayer);
    },
  );

  test(
    'persisted dislike and undislike analytics are emitted exactly once',
    () async {
      final audioPlayer = _FakeAudioPlayer();
      final analytics = _FakeAnalyticsCollector();
      final bloc = _createBloc(audioPlayer: audioPlayer, analytics: analytics);

      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 50,
          isDisliked: true,
          collectDislikeAnalytics: true,
          sourceContext: AutoplayContext(
            sourceType: AutoplaySourceType.playlist,
            sourceId: 6,
          ),
          sourceQueueIndex: 4,
          sourceWasPlaying: false,
        ),
      );
      await _settleBloc();
      bloc.add(
        const PersistedTrackPreferenceChanged(
          trackId: 50,
          isDisliked: false,
          collectDislikeAnalytics: true,
        ),
      );
      await _settleBloc();

      final preferenceEvents = analytics.events
          .where(
            (event) =>
                event.type == AnalyticsEventType.trackDislike ||
                event.type == AnalyticsEventType.trackUndislike,
          )
          .toList();
      expect(preferenceEvents, hasLength(2));
      expect(preferenceEvents.first.type.value, 'track_dislike');
      expect(preferenceEvents.first.trackId, 50);
      expect(preferenceEvents.first.metadata, {
        'sourceType': 'playlist',
        'sourceId': 6,
        'queueIndex': 4,
        'wasPlaying': false,
      });
      expect(preferenceEvents.last.type.value, 'track_undislike');
      expect(preferenceEvents.last.trackId, 50);

      await _dispose(bloc, audioPlayer);
    },
  );
}

PlayerBloc _createBloc({
  required _FakeAudioPlayer audioPlayer,
  _FakeAutoplayStorage? autoplayStorage,
  AnalyticsCollecting analytics = const NoopAnalyticsCollector(),
}) {
  return PlayerBloc(
    initialState: const PlayerState(selectedTrack: null, isPlaying: false),
    player: audioPlayer,
    autoplayStorage: autoplayStorage ?? _FakeAutoplayStorage(),
    errorReporter: _FakeErrorReporter(),
    analytics: analytics,
  );
}

Future<void> _settleBloc() async {
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _dispose(PlayerBloc bloc, _FakeAudioPlayer audioPlayer) async {
  await bloc.close();
  await audioPlayer.dispose();
}

AutoplayTracksBatch _batch(AutoplayContext context, List<Track> tracks) {
  return AutoplayTracksBatch(
    context: context,
    strategy: 'random_stub_v1',
    tracks: tracks,
  );
}

class _FakeAutoplayStorage implements AutoplayStorage {
  _FakeAutoplayStorage({this.batches = const [], this.blockingFirstBatch});

  final List<AutoplayTracksBatch> batches;
  final Future<AutoplayTracksBatch>? blockingFirstBatch;
  final List<_AutoplayRequest> requests = <_AutoplayRequest>[];

  @override
  Future<AutoplayTracksBatch> getNextTracks({
    required AutoplayContext context,
    required int count,
    required List<int> recentTrackIds,
    required List<int> excludedTrackIds,
  }) async {
    requests.add(
      _AutoplayRequest(
        context: context,
        count: count,
        recentTrackIds: recentTrackIds,
        excludedTrackIds: excludedTrackIds,
      ),
    );
    final requestIndex = requests.length - 1;
    if (requestIndex == 0 && blockingFirstBatch != null) {
      return blockingFirstBatch!;
    }
    if (requestIndex < batches.length) {
      return batches[requestIndex];
    }

    return AutoplayTracksBatch(
      context: context,
      strategy: 'empty_stub_v1',
      tracks: const [],
    );
  }
}

class _AutoplayRequest {
  const _AutoplayRequest({
    required this.context,
    required this.count,
    required this.recentTrackIds,
    required this.excludedTrackIds,
  });

  final AutoplayContext context;
  final int count;
  final List<int> recentTrackIds;
  final List<int> excludedTrackIds;
}

class _FakeAudioPlayer implements AudioPlayer {
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();
  final StreamController<bool> _hasPreviousTrackController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _hasNextTrackController =
      StreamController<bool>.broadcast();

  List<Track> _queue = <Track>[];
  int? _currentIndex;
  bool _isPlaying = false;

  final List<int> startedTrackIds = <int>[];
  final List<int> appendedTrackIds = <int>[];
  final List<Set<int>> removedUpcomingTrackIdSets = <Set<int>>[];
  int? startedInitialIndex;
  int stopCallCount = 0;

  List<int> get queueTrackIds => _queue.map((track) => track.id).toList();

  @override
  int? get currentIndex => _currentIndex;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Stream<Duration?> get durationStream => const Stream<Duration?>.empty();

  @override
  Stream<bool> get hasNextTrackStream => _hasNextTrackController.stream;

  @override
  Stream<bool> get hasPreviousTrackStream => _hasPreviousTrackController.stream;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;

  @override
  Stream<Duration> get positionStream => const Stream<Duration>.empty();

  @override
  Future<void> appendToQueue(List<Track> tracks) async {
    _queue = [..._queue, ...tracks];
    appendedTrackIds.addAll(tracks.map((track) => track.id));
    _emitNavigationState();
  }

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {
    _queue = List<Track>.of(tracks);
    _currentIndex = initialIndex;
    _isPlaying = true;
    startedInitialIndex = initialIndex;
    startedTrackIds
      ..clear()
      ..addAll(tracks.map((track) => track.id));
    _isPlayingController.add(true);
    _currentTrackController.add(_queue[initialIndex]);
    _emitNavigationState();
  }

  @override
  Future<void> dispose() async {
    await _isPlayingController.close();
    await _currentTrackController.close();
    await _hasPreviousTrackController.close();
    await _hasNextTrackController.close();
  }

  @override
  Future<void> removeUpcomingTracks(Set<int> trackIds) async {
    removedUpcomingTrackIdSets.add(Set<int>.of(trackIds));
    final safeCurrentIndex = _currentIndex;
    if (safeCurrentIndex == null) {
      return;
    }

    _queue = [
      ..._queue.take(safeCurrentIndex + 1),
      ..._queue
          .skip(safeCurrentIndex + 1)
          .where((track) => !trackIds.contains(track.id)),
    ];
    _emitNavigationState();
  }

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> skipToNextTrack() async {
    if (_currentIndex == null || _currentIndex == _queue.length - 1) {
      return;
    }

    _currentIndex = _currentIndex! + 1;
    _currentTrackController.add(_queue[_currentIndex!]);
    _emitNavigationState();
  }

  Future<void> advanceAutomatically() => skipToNextTrack();

  @override
  Future<void> skipToPreviousTrack() async {
    if (_currentIndex == null || _currentIndex == 0) {
      return;
    }

    _currentIndex = _currentIndex! - 1;
    _currentTrackController.add(_queue[_currentIndex!]);
    _emitNavigationState();
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    _isPlaying = false;
    _isPlayingController.add(false);
  }

  @override
  Future<void> togglePlay() async {
    _isPlaying = !_isPlaying;
    _isPlayingController.add(_isPlaying);
  }

  void _emitNavigationState() {
    _hasPreviousTrackController.add((_currentIndex ?? 0) > 0);
    _hasNextTrackController.add(
      _currentIndex != null && _currentIndex! < _queue.length - 1,
    );
  }
}

class _FakeAnalyticsCollector implements AnalyticsCollecting {
  final List<AnalyticsEvent> events = <AnalyticsEvent>[];

  @override
  Future<void> collect(AnalyticsEvent event) async {
    events.add(event);
  }

  @override
  Future<void> collectAll(List<AnalyticsEvent> events) async {
    this.events.addAll(events);
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> flushNow() async {}

  @override
  void start() {}
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

Track _track(int id, {bool isDisliked = false, bool isAvailable = true}) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Author', photos: [])],
    addionalInfo: const [],
    file: _FakeFile(),
    image: _FakeFile(),
    isFavorite: false,
    isDisliked: isDisliked,
    isAvailable: isAvailable,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
