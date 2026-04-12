import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();
}

final class PlayTrack extends PlayerEvent {
  final Track track;
  final List<Track> queue;

  PlayTrack(this.track, {List<Track>? queue}) : queue = queue ?? [track];

  @override
  List<Object?> get props => [track, queue];
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
  final AudioPlayer _player;
  final ErrorReporter _errorReporter;

  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<Track?>? _selectedTrackSubscription;
  StreamSubscription<bool>? _hasPreviousTrackSubscription;
  StreamSubscription<bool>? _hasNextTrackSubscription;

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
    required ErrorReporter errorReporter,
  }) : _player = player,
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

    on<PlayTrack>((event, emit) async {
      try {
        emit(state.copyWith(selectedTrack: NullableOption.value(event.track)));

        await _player.beginPlayingQueue(
          event.queue,
          initialIndex: event.queue.indexOf(event.track),
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
    });

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

    on<_SelectedTrackChanged>((event, emit) {
      emit(
        state.copyWith(
          selectedTrack: event.track == null
              ? NullableOption.nullable()
              : NullableOption.value(event.track!),
        ),
      );
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
