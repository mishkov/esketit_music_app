import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/use_case/shared/snapshot.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TracksListEvent extends Equatable {}

class LoadMoreTracks extends TracksListEvent {
  @override
  List<Object?> get props => [];
}

class TracksListBloc extends Bloc<TracksListEvent, TracksListState> {
  final TracksStorage _tracksStorage;

  TracksListBloc({
    required TracksListState initialState,
    required TracksStorage tracksStorage,
  }) : _tracksStorage = tracksStorage,
       super(initialState) {
    on<LoadMoreTracks>((event, emit) async {
      try {
        // TODO: emit loading tracks.

        final tracks = await _tracksStorage.getTracks(
          tracksPerPage: state.tracksPerPage,
          lastFetchedTrack: state.tracks.lastOrNull?.data,
        );

        emit(
          state.copyWith(
            tracks: [...state.tracks, ...tracks.map(Snapshot.done)],
          ),
        );
      } catch (error, stackTrace) {
        // TODO: emit error tracks.

        // TODO: report error to [ErrorReporter]
      }
    });
  }
}

class TracksListState extends Equatable {
  final List<Snapshot<Track>> tracks;
  final int tracksPerPage;

  const TracksListState({required this.tracks, required this.tracksPerPage});

  TracksListState copyWith({
    List<Snapshot<Track>>? tracks,
    int? tracksPerPage,
  }) {
    return TracksListState(
      tracks: tracks ?? this.tracks,
      tracksPerPage: tracksPerPage ?? this.tracksPerPage,
    );
  }

  @override
  List<Object?> get props => [tracks, tracksPerPage];
}
