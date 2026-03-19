import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PlayerEvent extends Equatable {}

class PlayTrack extends PlayerEvent {
  final Track track;

  PlayTrack(this.track);

  @override
  List<Object?> get props => [track];
}

class TogglePlay extends PlayerEvent {
  @override
  List<Object?> get props => [];
}

class _PlaybackStateChanged extends PlayerEvent {
  final bool isPlaying;

  _PlaybackStateChanged(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _player;
  final ErrorReporter _errorReporter;

  StreamSubscription<bool>? _isPlayingSubscription;

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

    on<PlayTrack>((event, emit) async {
      try {
        emit(state.copyWith(selectedTrack: NullableOption.value(event.track)));

        await _player.beginPlaying(event.track);
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

    on<_PlaybackStateChanged>((event, emit) {
      emit(state.copyWith(isPlaying: event.isPlaying));
    });
  }

  @override
  Future<void> close() async {
    await _isPlayingSubscription?.cancel();

    return super.close();
  }
}

class PlayerState extends Equatable {
  final Track? selectedTrack;
  final bool isPlaying;

  const PlayerState({required this.selectedTrack, required this.isPlaying});

  PlayerState copyWith({
    NullableOption<Track>? selectedTrack,
    bool? isPlaying,
  }) {
    return PlayerState(
      selectedTrack: selectedTrack == null
          ? this.selectedTrack
          : selectedTrack.value,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object?> get props => [selectedTrack, isPlaying];
}
