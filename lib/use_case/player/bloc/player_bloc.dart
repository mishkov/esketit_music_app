import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
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

  PlayTrack(
    this.track, {
    List<Track>? queue,
    this.autoplayContext,
  }) : queue = queue ?? [track];

  @override
  List<Object?> get props => [track, queue, autoplayContext];
}

final class StartAutoplayPlaybackRequested extends PlayerEvent {
  const StartAutoplayPlaybackRequested(this.autoplayContext);

  final AutoplayContext autoplayContext;

  @override
  List<Object?> get props => [autoplayContext];
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

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  static const int autoplayBatchSize = 10;
  static const int autoplayRecentTracksLimit = 30;
  static const int autoplayPrefetchThreshold = 2;

  final AudioPlayer _player;
  final AutoplayStorage _autoplayStorage;
  final ErrorReporter _errorReporter;
  final List<Track> _queue = <Track>[];
  final List<int> _recentTrackIds = <int>[];
  final Set<int> _excludedTrackIds = <int>{};

  AutoplayContext? _autoplayContext;
  bool _isAutoplayRequestInProgress = false;
  bool _isAutoplayExhausted = false;

  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<Track?>? _selectedTrackSubscription;
  StreamSubscription<bool>? _hasPreviousTrackSubscription;
  StreamSubscription<bool>? _hasNextTrackSubscription;

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
  }) : _player = player,
       _autoplayStorage = autoplayStorage,
       _errorReporter = errorReporter,
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

    on<PlayTrack>(_onPlayTrack);
    on<StartAutoplayPlaybackRequested>(_onStartAutoplayPlaybackRequested);

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
      }
    });

    on<SkipToPreviousTrackRequested>((event, emit) async {
      try {
        await _player.skipToPreviousTrack();
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to skip to previous track',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    });

    on<SkipToNextTrackRequested>((event, emit) async {
      try {
        await _ensureAutoplayQueuePrefilled();
        await _player.skipToNextTrack();
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to skip to next track',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    });

    on<SeekToPositionRequested>((event, emit) async {
      try {
        await _player.seekTo(event.position);
      } catch (error, stackTrace) {
        await _errorReporter.reportError(
          AppError(
            'Failed to seek playback position',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    });

    on<_PlaybackStateChanged>((event, emit) {
      emit(state.copyWith(isPlaying: event.isPlaying));
    });

    on<_SelectedTrackChanged>((event, emit) async {
      emit(
        state.copyWith(
          selectedTrack: event.track == null
              ? NullableOption.nullable()
              : NullableOption.value(event.track!),
        ),
      );

      final selectedTrack = event.track;
      if (selectedTrack == null) {
        return;
      }

      _recordRecentlyPlayedTrack(selectedTrack.id);
      await _ensureAutoplayQueuePrefilled();
    });

    on<_HasPreviousTrackChanged>((event, emit) {
      emit(state.copyWith(hasPreviousTrack: event.hasPreviousTrack));
    });

    on<_HasNextTrackChanged>((event, emit) {
      emit(state.copyWith(hasNextTrack: event.hasNextTrack));
    });
  }

  @override
  Future<void> close() async {
    await _isPlayingSubscription?.cancel();
    await _selectedTrackSubscription?.cancel();
    await _hasPreviousTrackSubscription?.cancel();
    await _hasNextTrackSubscription?.cancel();

    return super.close();
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<PlayerState> emit) async {
    try {
      final initialIndex = event.queue.indexOf(event.track);
      if (initialIndex < 0) {
        throw StateError('Selected track must exist in playback queue');
      }

      await _startPlayback(
        emit,
        track: event.track,
        queue: event.queue,
        initialIndex: initialIndex,
        autoplayContext: event.autoplayContext,
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
      final availableTracks = batch.tracks
          .where((track) => track.isAvailable)
          .toList(growable: false);
      if (availableTracks.isEmpty) {
        return;
      }

      await _startPlayback(
        emit,
        track: availableTracks.first,
        queue: availableTracks,
        initialIndex: 0,
        autoplayContext: event.autoplayContext,
      );
    } catch (error, stackTrace) {
      await _handleAutoplayFailure(
        message: 'Failed to start autoplay playback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startPlayback(
    Emitter<PlayerState> emit, {
    required Track track,
    required List<Track> queue,
    required int initialIndex,
    required AutoplayContext? autoplayContext,
  }) async {
    _replaceManagedQueue(queue);
    _configureAutoplaySession(autoplayContext, seededQueue: queue);

    emit(state.copyWith(selectedTrack: NullableOption.value(track)));

    await _player.beginPlayingQueue(queue, initialIndex: initialIndex);
    await _ensureAutoplayQueuePrefilled();
  }

  void _replaceManagedQueue(List<Track> queue) {
    _queue
      ..clear()
      ..addAll(queue);
  }

  void _configureAutoplaySession(
    AutoplayContext? autoplayContext, {
    required List<Track> seededQueue,
  }) {
    _autoplayContext = autoplayContext;
    _recentTrackIds.clear();
    _excludedTrackIds
      ..clear()
      ..addAll(seededQueue.map((track) => track.id));
    _isAutoplayRequestInProgress = false;
    _isAutoplayExhausted = false;
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
      final newTracks = batch.tracks
          .where(
            (track) => track.isAvailable && !_excludedTrackIds.contains(track.id),
          )
          .toList(growable: false);
      if (newTracks.isEmpty) {
        _isAutoplayExhausted = true;

        return;
      }

      _queue.addAll(newTracks);
      _excludedTrackIds.addAll(newTracks.map((track) => track.id));
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
    final currentIndex = _queue.indexWhere((item) => item.id == track.id);
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

  Map<String, Object?> _autoplayBreadcrumbData(AutoplayContext autoplayContext) {
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
