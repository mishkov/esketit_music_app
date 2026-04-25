import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
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
        nextBatch: AutoplayTracksBatch(
          context: const AutoplayContext(
            sourceType: AutoplaySourceType.playlist,
            sourceId: 7,
          ),
          strategy: 'random_stub_v1',
          tracks: [_track(3), _track(4)],
        ),
      );
      final bloc = PlayerBloc(
        initialState: const PlayerState(selectedTrack: null, isPlaying: false),
        player: audioPlayer,
        autoplayStorage: autoplayStorage,
        errorReporter: _FakeErrorReporter(),
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

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

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

      await bloc.close();
      await audioPlayer.dispose();
    },
  );

  test('my vibe request starts playback from autoplay response', () async {
    final audioPlayer = _FakeAudioPlayer();
    final autoplayStorage = _FakeAutoplayStorage(
      nextBatch: AutoplayTracksBatch(
        context: const AutoplayContext.myVibe(),
        strategy: 'random_stub_v1',
        tracks: [_track(11), _track(12)],
      ),
    );
    final bloc = PlayerBloc(
      initialState: const PlayerState(selectedTrack: null, isPlaying: false),
      player: audioPlayer,
      autoplayStorage: autoplayStorage,
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(const StartAutoplayPlaybackRequested(AutoplayContext.myVibe()));

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.selectedTrack?.id, 11);
    expect(audioPlayer.startedTrackIds, [11, 12]);
    expect(
      autoplayStorage.requests.single.context,
      const AutoplayContext.myVibe(),
    );

    await bloc.close();
    await audioPlayer.dispose();
  });
}

class _FakeAutoplayStorage implements AutoplayStorage {
  _FakeAutoplayStorage({required this.nextBatch});

  final AutoplayTracksBatch nextBatch;
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

    return nextBatch;
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

  final List<int> startedTrackIds = <int>[];
  final List<int> appendedTrackIds = <int>[];

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
  Future<void> togglePlay() async {}

  void _emitNavigationState() {
    _hasPreviousTrackController.add((_currentIndex ?? 0) > 0);
    _hasNextTrackController.add(
      _currentIndex != null && _currentIndex! < _queue.length - 1,
    );
  }
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Author', photos: [])],
    addionalInfo: const [],
    file: _FakeFile(),
    image: _FakeFile(),
    isFavorite: false,
    isAvailable: true,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
