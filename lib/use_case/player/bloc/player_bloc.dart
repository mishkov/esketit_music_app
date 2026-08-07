import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_collecting.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();
}

final class PlayTrack extends PlayerEvent {
  final Track track;
  final List<Track> queue;
  final AutoplayContext? autoplayContext;

  PlayTrack(this.track, {List<Track>? queue, this.autoplayContext})
    : queue = queue ?? [track];

  @override
  List<Object?> get props => [track, queue, autoplayContext];
}

final class StartAutoplayPlaybackRequested extends PlayerEvent {
  const StartAutoplayPlaybackRequested(this.autoplayContext);

  final AutoplayContext autoplayContext;

  @override
  List<Object?> get props => [autoplayContext];
}

final class PersistedTrackPreferenceChanged extends PlayerEvent {
  const PersistedTrackPreferenceChanged({
    required this.trackId,
    required this.isDisliked,
    required this.collectDislikeAnalytics,
    this.sourceContext,
    this.sourceQueueIndex,
    this.sourceWasPlaying,
  });

  final int trackId;
  final bool isDisliked;
  final bool collectDislikeAnalytics;
  final AutoplayContext? sourceContext;
  final int? sourceQueueIndex;
  final bool? sourceWasPlaying;

  @override
  List<Object?> get props => [
    trackId,
    isDisliked,
    collectDislikeAnalytics,
    sourceContext,
    sourceQueueIndex,
    sourceWasPlaying,
  ];
}

final class TogglePlay extends PlayerEvent {
  const TogglePlay();

  @override
  List<Object?> get props => [];
}

final class SkipToPreviousTrackRequested extends PlayerEvent {
  const SkipToPreviousTrackRequested();

  @override
  List<Object?> get props => [];
}

final class SkipToNextTrackRequested extends PlayerEvent {
  const SkipToNextTrackRequested();

  @override
  List<Object?> get props => [];
}

final class SeekToPositionRequested extends PlayerEvent {
  const SeekToPositionRequested(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

final class _PlaybackStateChanged extends PlayerEvent {
  final bool isPlaying;

  const _PlaybackStateChanged(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

final class _SelectedTrackChanged extends PlayerEvent {
  final Track? track;

  const _SelectedTrackChanged(this.track);

  @override
  List<Object?> get props => [track];
}

final class _HasPreviousTrackChanged extends PlayerEvent {
  const _HasPreviousTrackChanged(this.hasPreviousTrack);

  final bool hasPreviousTrack;

  @override
  List<Object?> get props => [hasPreviousTrack];
}

final class _HasNextTrackChanged extends PlayerEvent {
  const _HasNextTrackChanged(this.hasNextTrack);

  final bool hasNextTrack;

  @override
  List<Object?> get props => [hasNextTrack];
}

final class _PlaybackPositionChanged extends PlayerEvent {
  const _PlaybackPositionChanged(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

final class _PlaybackDurationChanged extends PlayerEvent {
  const _PlaybackDurationChanged(this.duration);

  final Duration? duration;

  @override
  List<Object?> get props => [duration];
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  static const int autoplayBatchSize = 10;
  static const int autoplayRecentTracksLimit = 30;
  static const int autoplayPrefetchThreshold = 2;

  final AudioPlayer _player;
  final AutoplayStorage _autoplayStorage;
  final ErrorReporter _errorReporter;
  final AnalyticsCollecting _analytics;
  final List<Track> _queue = <Track>[];
  final List<int> _recentTrackIds = <int>[];
  final Set<int> _excludedTrackIds = <int>{};
  final Set<int> _knownDislikedTrackIds = <int>{};
  final Map<int, bool> _persistedTrackDislikeOverrides = <int, bool>{};

  AutoplayContext? _autoplayContext;
  Track? _previousAnalyticsTrack;
  String? _pendingTrackChangeReason;
  Duration _latestPosition = Duration.zero;
  Duration? _latestDuration;
  int? _completedAnalyticsTrackId;
  bool _isAutoplayRequestInProgress = false;
  bool _isAutoplayExhausted = false;
  bool _skipNextSelectedTrackAutoplayPrefetch = false;
  bool _suppressNextResumeAnalyticsEvent = false;
  bool _suppressNextPauseAnalyticsEvent = false;
  bool _hasSeenPlaybackState = false;

  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<Track?>? _selectedTrackSubscription;
  StreamSubscription<bool>? _hasPreviousTrackSubscription;
  StreamSubscription<bool>? _hasNextTrackSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  Duration get currentPosition => _player.currentPosition;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerPlaybackProgress> get playbackProgressStream {
    return Stream<PlayerPlaybackProgress>.multi((controller) {
      var latestPosition = Duration.zero;
      var latestDuration = Duration.zero;

      void emitPlaybackProgress() {
        controller.add(
          PlayerPlaybackProgress(
            position: latestPosition,
            duration: latestDuration,
          ),
        );
      }

      emitPlaybackProgress();

      final positionSubscription = positionStream.listen((position) {
        latestPosition = position;
        emitPlaybackProgress();
      });
      final durationSubscription = durationStream.listen((duration) {
        latestDuration = duration ?? Duration.zero;
        emitPlaybackProgress();
      });

      controller.onCancel = () async {
        await positionSubscription.cancel();
        await durationSubscription.cancel();
      };
    });
  }

  PlayerBloc({
    required PlayerState initialState,
    required AudioPlayer player,
    required AutoplayStorage autoplayStorage,
    required ErrorReporter errorReporter,
    AnalyticsCollecting analytics = const NoopAnalyticsCollector(),
  }) : _player = player,
       _autoplayStorage = autoplayStorage,
       _errorReporter = errorReporter,
       _analytics = analytics,
       super(initialState) {
    _isPlayingSubscription = _player.isPlayingStream.listen((isPlaying) {
      add(_PlaybackStateChanged(isPlaying));
    });
    _selectedTrackSubscription = _player.currentTrackStream.listen((track) {
      add(_SelectedTrackChanged(track));
    });
    _hasPreviousTrackSubscription = _player.hasPreviousTrackStream.listen((
      hasPreviousTrack,
    ) {
      add(_HasPreviousTrackChanged(hasPreviousTrack));
    });
    _hasNextTrackSubscription = _player.hasNextTrackStream.listen((
      hasNextTrack,
    ) {
      add(_HasNextTrackChanged(hasNextTrack));
    });
    _positionSubscription = _player.positionStream.listen((position) {
      add(_PlaybackPositionChanged(position));
    });
    _durationSubscription = _player.durationStream.listen((duration) {
      add(_PlaybackDurationChanged(duration));
    });

    on<PlayTrack>(_onPlayTrack);
    on<StartAutoplayPlaybackRequested>(_onStartAutoplayPlaybackRequested);
    on<PersistedTrackPreferenceChanged>(
      _onPersistedTrackPreferenceChanged,
      transformer: _sequentialPreferenceChanges(),
    );

    on<TogglePlay>((event, emit) async {
      try {
        await _player.togglePlay();
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to toggle player state',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        await _collectPlaybackError(
          state.selectedTrack,
          error: error,
          stackTrace: stackTrace,
          fatal: false,
        );
      }
    });

    on<SkipToPreviousTrackRequested>((event, emit) async {
      try {
        if (state.hasPreviousTrack) {
          await _collectTrackSkip(
            reason: 'manual_previous',
            skipDirection: 'backward',
            nextTrack: _previousTrackBefore(state.selectedTrack),
          );
          _pendingTrackChangeReason = 'manual_previous';
        }
        await _player.skipToPreviousTrack();
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to skip to previous track',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        await _collectPlaybackError(
          state.selectedTrack,
          error: error,
          stackTrace: stackTrace,
          fatal: false,
        );
      }
    });

    on<SkipToNextTrackRequested>((event, emit) async {
      try {
        await _ensureAutoplayQueuePrefilled();
        if (state.hasNextTrack ||
            _nextTrackAfter(state.selectedTrack) != null) {
          await _collectTrackSkip(
            reason: 'manual_next',
            skipDirection: 'forward',
            nextTrack: _nextTrackAfter(state.selectedTrack),
          );
          _pendingTrackChangeReason = 'manual_next';
        }
        await _player.skipToNextTrack();
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to skip to next track',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        await _collectPlaybackError(
          state.selectedTrack,
          error: error,
          stackTrace: stackTrace,
          fatal: false,
        );
      }
    });

    on<SeekToPositionRequested>((event, emit) async {
      try {
        final fromPosition = _latestPosition;
        await _player.seekTo(event.position);
        final selectedTrack = state.selectedTrack;
        if (selectedTrack != null) {
          await _collectAnalytics(
            AnalyticsEvent(
              type: AnalyticsEventType.seek,
              trackId: selectedTrack.id,
              positionMs: event.position.inMilliseconds,
              durationMs: _durationMs,
              metadata: {
                'fromPositionMs': fromPosition.inMilliseconds,
                'toPositionMs': event.position.inMilliseconds,
                'method': 'scrubber',
              },
            ),
          );
        }
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to seek playback position',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
        await _collectPlaybackError(
          state.selectedTrack,
          error: error,
          stackTrace: stackTrace,
          fatal: false,
        );
      }
    });

    on<_PlaybackStateChanged>((event, emit) async {
      final wasPlaying = state.isPlaying;
      emit(state.copyWith(isPlaying: event.isPlaying));

      if (!_hasSeenPlaybackState) {
        _hasSeenPlaybackState = true;

        return;
      }
      if (event.isPlaying && !wasPlaying && state.selectedTrack != null) {
        if (_suppressNextResumeAnalyticsEvent) {
          _suppressNextResumeAnalyticsEvent = false;

          return;
        }
        await _collectAnalytics(
          AnalyticsEvent(
            type: AnalyticsEventType.resume,
            trackId: state.selectedTrack!.id,
            positionMs: _latestPosition.inMilliseconds,
            durationMs: _durationMs,
            metadata: {'reason': 'user'},
          ),
        );
      }
      if (!event.isPlaying && wasPlaying && state.selectedTrack != null) {
        if (_suppressNextPauseAnalyticsEvent) {
          _suppressNextPauseAnalyticsEvent = false;

          return;
        }
        await _collectPause(reason: 'user');
      }
    });

    on<_SelectedTrackChanged>((event, emit) async {
      final previousTrack = state.selectedTrack ?? _previousAnalyticsTrack;
      emit(
        state.copyWith(
          selectedTrack: event.track == null
              ? NullableOption.nullable()
              : NullableOption.value(event.track!),
        ),
      );

      final selectedTrack = event.track;
      if (selectedTrack == null) {
        _previousAnalyticsTrack = null;
        _completedAnalyticsTrackId = null;

        return;
      }

      if (previousTrack != null && previousTrack.id != selectedTrack.id) {
        await _collectAnalytics(
          AnalyticsEvent(
            type: AnalyticsEventType.trackChange,
            trackId: selectedTrack.id,
            positionMs: 0,
            durationMs: _durationMs,
            metadata: {
              'previousTrackId': previousTrack.id,
              'reason': _pendingTrackChangeReason ?? 'autoplay',
            },
          ),
        );
      }
      _previousAnalyticsTrack = selectedTrack;
      _pendingTrackChangeReason = null;
      _latestPosition = Duration.zero;
      _completedAnalyticsTrackId = null;

      _recordRecentlyPlayedTrack(selectedTrack.id);
      if (_skipNextSelectedTrackAutoplayPrefetch) {
        _skipNextSelectedTrackAutoplayPrefetch = false;

        return;
      }

      await _ensureAutoplayQueuePrefilled();
    });

    on<_HasPreviousTrackChanged>((event, emit) {
      emit(state.copyWith(hasPreviousTrack: event.hasPreviousTrack));
    });

    on<_HasNextTrackChanged>((event, emit) {
      emit(state.copyWith(hasNextTrack: event.hasNextTrack));
    });
    on<_PlaybackPositionChanged>(_onPlaybackPositionChanged);
    on<_PlaybackDurationChanged>(_onPlaybackDurationChanged);
  }

  static EventTransformer<PersistedTrackPreferenceChanged>
  _sequentialPreferenceChanges() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  @override
  Future<void> close() async {
    await _isPlayingSubscription?.cancel();
    await _selectedTrackSubscription?.cancel();
    await _hasPreviousTrackSubscription?.cancel();
    await _hasNextTrackSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();

    return super.close();
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<PlayerState> emit) async {
    try {
      final sourceInitialIndex = _selectedTrackIndex(
        queue: event.queue,
        selectedTrack: event.track,
      );
      if (sourceInitialIndex < 0) {
        throw StateError('Selected track must exist in playback queue');
      }
      _rememberDislikedTracks([...event.queue, event.track]);

      final eligibleQueue = <Track>[];
      var eligibleInitialIndex = 0;
      for (var index = 0; index < event.queue.length; index++) {
        final isExplicitlySelected = index == sourceInitialIndex;
        final track = isExplicitlySelected ? event.track : event.queue[index];
        if (isExplicitlySelected) {
          eligibleInitialIndex = eligibleQueue.length;
          eligibleQueue.add(track);

          continue;
        }
        if (track.isAvailable && !_isKnownDisliked(track)) {
          eligibleQueue.add(track);
        }
      }

      await _startPlayback(
        emit,
        track: event.track,
        queue: eligibleQueue,
        initialIndex: eligibleInitialIndex,
        autoplayContext: event.autoplayContext,
        reason: 'user_selected_track',
        shouldPrefetchAutoplayAfterStart: true,
        seededExcludedTrackIds: event.queue.map((track) => track.id),
      );
    } catch (error, stackTrace) {
      emit(state.copyWith(isPlaying: false));
      await _errorReporter.reportError(
        AppError(
          'Failed to play track ${event.track.id}',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
      await _collectPlaybackError(
        event.track,
        error: error,
        stackTrace: stackTrace,
        fatal: true,
      );
    }
  }

  Future<void> _onStartAutoplayPlaybackRequested(
    StartAutoplayPlaybackRequested event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Starting autoplay playback',
          category: Category.uiClick,
          data: _autoplayBreadcrumbData(event.autoplayContext),
        ),
      );

      final batch = await _autoplayStorage.getNextTracks(
        context: event.autoplayContext,
        count: autoplayBatchSize,
        recentTrackIds: const <int>[],
        excludedTrackIds: const <int>[],
      );
      _rememberDislikedTracks(batch.tracks);
      final eligibleTracks = batch.tracks
          .where((track) => track.isAvailable && !_isKnownDisliked(track))
          .toList(growable: false);
      if (eligibleTracks.isEmpty) {
        return;
      }

      await _startPlayback(
        emit,
        track: eligibleTracks.first,
        queue: eligibleTracks,
        initialIndex: 0,
        autoplayContext: event.autoplayContext,
        reason: 'autoplay',
        shouldPrefetchAutoplayAfterStart: false,
        seededExcludedTrackIds: batch.tracks.map((track) => track.id),
      );
    } catch (error, stackTrace) {
      await _handleAutoplayFailure(
        message: 'Failed to start autoplay playback',
        error: error,
        stackTrace: stackTrace,
      );
      await _collectPlaybackError(
        state.selectedTrack,
        error: error,
        stackTrace: stackTrace,
        fatal: false,
      );
    }
  }

  Future<void> _onPersistedTrackPreferenceChanged(
    PersistedTrackPreferenceChanged event,
    Emitter<PlayerState> emit,
  ) async {
    _persistedTrackDislikeOverrides[event.trackId] = event.isDisliked;
    if (event.isDisliked) {
      _knownDislikedTrackIds.add(event.trackId);
    } else {
      _knownDislikedTrackIds.remove(event.trackId);
    }

    if (event.collectDislikeAnalytics) {
      await _collectTrackPreferenceAnalytics(event);
    }
    if (!event.isDisliked) {
      return;
    }

    final selectedTrack = state.selectedTrack;
    final isCurrentTrack = selectedTrack?.id == event.trackId;

    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Applying persisted track dislike to playback queue',
          data: {
            'trackId': event.trackId,
            'isCurrentTrack': isCurrentTrack,
            'knownDislikedTracksCount': _knownDislikedTrackIds.length,
          },
        ),
      );

      final currentIndex = _player.currentIndex;
      await _player.removeUpcomingTracks(
        Set<int>.unmodifiable(_knownDislikedTrackIds),
      );
      _removeKnownDislikedUpcomingTracks(currentIndex);

      if (!isCurrentTrack) {
        await _ensureAutoplayQueuePrefilled();

        return;
      }

      var nextTrack = _nextTrackAfter(selectedTrack);
      if (nextTrack == null) {
        await _ensureAutoplayQueuePrefilled();
        nextTrack = _nextTrackAfter(selectedTrack);
      }
      if (nextTrack == null) {
        final shouldSuppressPauseAnalytics = state.isPlaying;
        _suppressNextPauseAnalyticsEvent = shouldSuppressPauseAnalytics;
        try {
          await _player.stop();
        } catch (_) {
          if (shouldSuppressPauseAnalytics) {
            _suppressNextPauseAnalyticsEvent = false;
          }
          rethrow;
        }

        return;
      }

      await _collectTrackSkip(
        reason: 'dislike',
        skipDirection: 'forward',
        nextTrack: nextTrack,
      );
      _pendingTrackChangeReason = 'dislike';
      await _player.skipToNextTrack();
    } catch (error, stackTrace) {
      _pendingTrackChangeReason = null;
      await _errorReporter.reportError(
        AppError(
          'Failed to apply disliked track ${event.trackId} to playback',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
      await _collectPlaybackError(
        selectedTrack,
        error: error,
        stackTrace: stackTrace,
        fatal: false,
      );
    }
  }

  Future<void> _startPlayback(
    Emitter<PlayerState> emit, {
    required Track track,
    required List<Track> queue,
    required int initialIndex,
    required AutoplayContext? autoplayContext,
    required String reason,
    required bool shouldPrefetchAutoplayAfterStart,
    Iterable<int>? seededExcludedTrackIds,
  }) async {
    _replaceManagedQueue(queue);
    _configureAutoplaySession(
      autoplayContext,
      seededExcludedTrackIds:
          seededExcludedTrackIds ?? queue.map((track) => track.id),
    );
    _skipNextSelectedTrackAutoplayPrefetch = !shouldPrefetchAutoplayAfterStart;

    emit(state.copyWith(selectedTrack: NullableOption.value(track)));

    _suppressNextResumeAnalyticsEvent = true;
    await _player.beginPlayingQueue(queue, initialIndex: initialIndex);
    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.play,
        trackId: track.id,
        playlistId: _playlistIdFrom(autoplayContext),
        albumId: _albumIdFrom(autoplayContext),
        positionMs: 0,
        durationMs: _durationMs,
        metadata: {
          ..._playbackSourceMetadata(autoplayContext),
          'queueIndex': initialIndex,
          'autoplay': reason == 'autoplay',
          'reason': reason,
        },
      ),
    );
    if (!shouldPrefetchAutoplayAfterStart) {
      return;
    }

    _recordRecentlyPlayedTrack(track.id);
    await _ensureAutoplayQueuePrefilled();
  }

  void _replaceManagedQueue(List<Track> queue) {
    _queue
      ..clear()
      ..addAll(queue);
  }

  void _removeKnownDislikedUpcomingTracks(int? currentIndex) {
    if (currentIndex == null ||
        currentIndex < 0 ||
        currentIndex >= _queue.length) {
      return;
    }

    final updatedQueue = <Track>[
      ..._queue.take(currentIndex + 1),
      ..._queue
          .skip(currentIndex + 1)
          .where((track) => !_isKnownDisliked(track)),
    ];
    _replaceManagedQueue(updatedQueue);
  }

  void _rememberDislikedTracks(Iterable<Track> tracks) {
    for (final track in tracks) {
      final isDisliked =
          _persistedTrackDislikeOverrides[track.id] ?? track.isDisliked;
      if (isDisliked) {
        _knownDislikedTrackIds.add(track.id);
      } else {
        _knownDislikedTrackIds.remove(track.id);
      }
    }
  }

  bool _isKnownDisliked(Track track) {
    return _knownDislikedTrackIds.contains(track.id);
  }

  void _configureAutoplaySession(
    AutoplayContext? autoplayContext, {
    required Iterable<int> seededExcludedTrackIds,
  }) {
    _autoplayContext = autoplayContext;
    _recentTrackIds.clear();
    _excludedTrackIds
      ..clear()
      ..addAll(seededExcludedTrackIds);
    _isAutoplayRequestInProgress = false;
    _isAutoplayExhausted = false;
    _skipNextSelectedTrackAutoplayPrefetch = false;
  }

  void _recordRecentlyPlayedTrack(int trackId) {
    _excludedTrackIds.add(trackId);
    if (_recentTrackIds.isNotEmpty && _recentTrackIds.last == trackId) {
      return;
    }

    _recentTrackIds.add(trackId);
    if (_recentTrackIds.length > autoplayRecentTracksLimit) {
      _recentTrackIds.removeRange(
        0,
        _recentTrackIds.length - autoplayRecentTracksLimit,
      );
    }
  }

  Future<void> _ensureAutoplayQueuePrefilled() async {
    final autoplayContext = _autoplayContext;
    final selectedTrack = state.selectedTrack;
    if (autoplayContext == null ||
        selectedTrack == null ||
        _isAutoplayRequestInProgress ||
        _isAutoplayExhausted) {
      return;
    }

    final remainingTracksCount = _remainingTracksCountAfter(selectedTrack);
    if (remainingTracksCount > autoplayPrefetchThreshold) {
      return;
    }

    _isAutoplayRequestInProgress = true;

    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Requesting autoplay continuation',
          category: Category.http,
          data: {
            ..._autoplayBreadcrumbData(autoplayContext),
            'recentTrackIdsCount': _recentTrackIds.length,
            'excludedTrackIdsCount': _excludedTrackIds.length,
          },
        ),
      );

      final batch = await _autoplayStorage.getNextTracks(
        context: autoplayContext,
        count: autoplayBatchSize,
        recentTrackIds: List<int>.unmodifiable(_recentTrackIds),
        excludedTrackIds: List<int>.unmodifiable(_excludedTrackIds),
      );
      _rememberDislikedTracks(batch.tracks);
      final newTracks = batch.tracks
          .where(
            (track) =>
                track.isAvailable &&
                !_isKnownDisliked(track) &&
                !_excludedTrackIds.contains(track.id),
          )
          .toList(growable: false);
      _excludedTrackIds.addAll(batch.tracks.map((track) => track.id));
      if (newTracks.isEmpty) {
        _isAutoplayExhausted = true;

        return;
      }

      _queue.addAll(newTracks);
      await _player.appendToQueue(newTracks);
    } catch (error, stackTrace) {
      await _handleAutoplayFailure(
        message: 'Failed to request autoplay continuation',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isAutoplayRequestInProgress = false;
    }
  }

  int _remainingTracksCountAfter(Track track) {
    final currentIndex = _managedCurrentIndex(track);
    if (currentIndex < 0) {
      return 0;
    }

    return _queue.length - currentIndex - 1;
  }

  Future<void> _handleAutoplayFailure({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    _autoplayContext = null;

    if (error is UnauthorizedAppError || error is ForbiddenAppError) {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: Category.http,
          data: {'reason': error.runtimeType.toString()},
        ),
      );

      return;
    }

    await _errorReporter.reportError(
      AppError(message, cause: error, stackTrace: stackTrace),
    );
  }

  void _onPlaybackPositionChanged(
    _PlaybackPositionChanged event,
    Emitter<PlayerState> emit,
  ) {
    _latestPosition = event.position;
    unawaited(_collectTrackCompleteIfNeeded());
  }

  void _onPlaybackDurationChanged(
    _PlaybackDurationChanged event,
    Emitter<PlayerState> emit,
  ) {
    _latestDuration = event.duration;
    unawaited(_collectTrackCompleteIfNeeded());
  }

  Future<void> _collectTrackCompleteIfNeeded() async {
    final selectedTrack = state.selectedTrack;
    final duration = _latestDuration;
    if (selectedTrack == null ||
        duration == null ||
        duration == Duration.zero ||
        _completedAnalyticsTrackId == selectedTrack.id) {
      return;
    }

    final completionPercent = _completionPercent(
      position: _latestPosition,
      duration: duration,
    );
    if (completionPercent < 98) {
      return;
    }

    _completedAnalyticsTrackId = selectedTrack.id;
    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.trackComplete,
        trackId: selectedTrack.id,
        positionMs: _latestPosition.inMilliseconds,
        durationMs: duration.inMilliseconds,
        metadata: {
          'completionPercent': completionPercent,
          if (_nextTrackAfter(selectedTrack) != null)
            'nextTrackId': _nextTrackAfter(selectedTrack)!.id,
        },
      ),
    );
  }

  Future<void> _collectPause({required String reason}) async {
    final selectedTrack = state.selectedTrack;
    if (selectedTrack == null) {
      return;
    }

    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.pause,
        trackId: selectedTrack.id,
        positionMs: _latestPosition.inMilliseconds,
        durationMs: _durationMs,
        metadata: {'reason': reason},
      ),
    );
  }

  Future<void> _collectTrackSkip({
    required String reason,
    required String skipDirection,
    required Track? nextTrack,
  }) async {
    final selectedTrack = state.selectedTrack;
    if (selectedTrack == null) {
      return;
    }

    final duration = _latestDuration;
    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.trackSkip,
        trackId: selectedTrack.id,
        positionMs: _latestPosition.inMilliseconds,
        durationMs: _durationMs,
        metadata: {
          'reason': reason,
          'skipDirection': skipDirection,
          'playedMs': _latestPosition.inMilliseconds,
          if (duration != null && duration != Duration.zero)
            'playedPercent': _completionPercent(
              position: _latestPosition,
              duration: duration,
            ),
          if (nextTrack != null) 'nextTrackId': nextTrack.id,
        },
      ),
    );
  }

  Future<void> _collectPlaybackError(
    Track? track, {
    required Object error,
    required StackTrace stackTrace,
    required bool fatal,
  }) async {
    if (track == null) {
      return;
    }

    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.playbackError,
        trackId: track.id,
        positionMs: _latestPosition.inMilliseconds,
        durationMs: _durationMs,
        metadata: {
          'errorCode': error.runtimeType.toString(),
          'errorMessage': error.toString(),
          'fatal': fatal,
          'retryable': !fatal,
        },
      ),
    );
  }

  Future<void> _collectTrackPreferenceAnalytics(
    PersistedTrackPreferenceChanged event,
  ) async {
    final isCurrentTrack = state.selectedTrack?.id == event.trackId;
    final sourceContext =
        event.sourceContext ?? (isCurrentTrack ? _autoplayContext : null);
    final sourceQueueIndex =
        event.sourceQueueIndex ??
        (isCurrentTrack ? _player.currentIndex : null);
    final sourceWasPlaying =
        event.sourceWasPlaying ?? (isCurrentTrack ? state.isPlaying : null);

    await _collectAnalytics(
      AnalyticsEvent(
        type: event.isDisliked
            ? AnalyticsEventType.trackDislike
            : AnalyticsEventType.trackUndislike,
        trackId: event.trackId,
        playlistId: _playlistIdFrom(sourceContext),
        albumId: _albumIdFrom(sourceContext),
        metadata: {
          ..._playbackSourceMetadata(sourceContext),
          'queueIndex': ?sourceQueueIndex,
          'wasPlaying': ?sourceWasPlaying,
        },
      ),
    );
  }

  Future<void> _collectAnalytics(AnalyticsEvent event) async {
    try {
      await _analytics.collect(event);
    } catch (error, stackTrace) {
      await _errorReporter.reportError(
        AppError(
          'Analytics collector leaked an error into player logic',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Map<String, Object?> _playbackSourceMetadata(
    AutoplayContext? autoplayContext,
  ) {
    if (autoplayContext == null) {
      return const {'sourceType': 'unknown'};
    }

    return {
      'sourceType': autoplayContext.sourceType.name,
      'sourceId': autoplayContext.sourceId,
    };
  }

  int? _playlistIdFrom(AutoplayContext? autoplayContext) {
    if (autoplayContext?.sourceType != AutoplaySourceType.playlist) {
      return null;
    }

    return autoplayContext?.sourceId;
  }

  int? _albumIdFrom(AutoplayContext? autoplayContext) {
    if (autoplayContext?.sourceType != AutoplaySourceType.album) {
      return null;
    }

    return autoplayContext?.sourceId;
  }

  Track? _nextTrackAfter(Track? track) {
    if (track == null) {
      return null;
    }
    final currentIndex = _managedCurrentIndex(track);
    if (currentIndex < 0 || currentIndex >= _queue.length - 1) {
      return null;
    }

    return _queue[currentIndex + 1];
  }

  Track? _previousTrackBefore(Track? track) {
    if (track == null) {
      return null;
    }
    final currentIndex = _managedCurrentIndex(track);
    if (currentIndex <= 0) {
      return null;
    }

    return _queue[currentIndex - 1];
  }

  int _managedCurrentIndex(Track track) {
    final playerCurrentIndex = _player.currentIndex;
    if (playerCurrentIndex != null &&
        playerCurrentIndex >= 0 &&
        playerCurrentIndex < _queue.length) {
      return playerCurrentIndex;
    }

    return _queue.indexWhere((item) => item.id == track.id);
  }

  int _selectedTrackIndex({
    required List<Track> queue,
    required Track selectedTrack,
  }) {
    final identicalIndex = queue.indexWhere(
      (track) => identical(track, selectedTrack),
    );
    if (identicalIndex >= 0) {
      return identicalIndex;
    }

    final equalIndex = queue.indexOf(selectedTrack);
    if (equalIndex >= 0) {
      return equalIndex;
    }

    return queue.indexWhere((track) => track.id == selectedTrack.id);
  }

  int? get _durationMs => _latestDuration?.inMilliseconds;

  double _completionPercent({
    required Duration position,
    required Duration duration,
  }) {
    if (duration == Duration.zero) {
      return 0;
    }

    return position.inMilliseconds / duration.inMilliseconds * 100;
  }

  Map<String, Object?> _autoplayBreadcrumbData(
    AutoplayContext autoplayContext,
  ) {
    return {
      'sourceType': autoplayContext.sourceType.name,
      'sourceId': autoplayContext.sourceId,
      'profile': autoplayContext.profile,
    };
  }
}

/// Current playback progress of the selected track.
///
/// [position] is the current playback point.
/// [duration] is the full length of the current track.
class PlayerPlaybackProgress extends Equatable {
  /// Current playback point of the selected track.
  final Duration position;

  /// Full length of the selected track.
  final Duration duration;

  const PlayerPlaybackProgress({
    required this.position,
    required this.duration,
  });

  @override
  List<Object> get props => [position, duration];
}

class PlayerState extends Equatable {
  final Track? selectedTrack;
  final bool isPlaying;
  final bool hasPreviousTrack;
  final bool hasNextTrack;

  const PlayerState({
    required this.selectedTrack,
    required this.isPlaying,
    this.hasPreviousTrack = false,
    this.hasNextTrack = false,
  });

  PlayerState copyWith({
    NullableOption<Track>? selectedTrack,
    bool? isPlaying,
    bool? hasPreviousTrack,
    bool? hasNextTrack,
  }) {
    return PlayerState(
      selectedTrack: selectedTrack == null
          ? this.selectedTrack
          : selectedTrack.value,
      isPlaying: isPlaying ?? this.isPlaying,
      hasPreviousTrack: hasPreviousTrack ?? this.hasPreviousTrack,
      hasNextTrack: hasNextTrack ?? this.hasNextTrack,
    );
  }

  @override
  List<Object?> get props => [
    selectedTrack,
    isPlaying,
    hasPreviousTrack,
    hasNextTrack,
  ];
}
