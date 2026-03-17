import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
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

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioPlayer _player;

  PlayerBloc({required PlayerState initialState, required AudioPlayer player})
    : _player = player,
      super(initialState) {
    on<PlayTrack>((event, emit) async {
      try {
        emit(
          state.copyWith(
            selectedTrack: NullableOption.value(event.track),
            isPlaying: true,
          ),
        );

        await _player.beginPlaying(event.track);

        emit(
          state.copyWith(
            selectedTrack: NullableOption.value(event.track),
            isPlaying: false,
          ),
        );
      } catch (error, stackTrace) {
        // TODO: reporter error.
      }
    });

    on<TogglePlay>((event, emit) async {
      try {
        emit(state.copyWith(isPlaying: !state.isPlaying));

        await _player.togglePlay();
      } catch (error, stackTrace) {
        // TODO: reporter error.
      }
    });
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
