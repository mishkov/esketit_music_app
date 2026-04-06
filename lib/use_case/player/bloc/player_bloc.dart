import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PlayerEvent extends Equatable {}

final class PlayTrack extends PlayerEvent {
  final Track track;
  final List<Track> queue;

  PlayTrack(this.track, {List<Track>? queue}) : queue = queue ?? [track];

  @override
  List<Object?> get props => [track, queue];
}

final class TogglePlay extends PlayerEvent {
  @override
  List<Object?> get props => [];
}

final class _PlaybackStateChanged extends PlayerEvent {
  final bool isPlaying;

  _PlaybackStateChanged(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

final class _SelectedTrackChanged extends PlayerEvent {
  final Track? track;

  _SelectedTrackChanged(this.track);

  @override
  List<Object?> get props => [track];
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _player;
  final ErrorReporter _errorReporter;

  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<Track?>? _selectedTrackSubscription;

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
  }

  @override
  Future<void> close() async {
    await _isPlayingSubscription?.cancel();
    await _selectedTrackSubscription?.cancel();

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
