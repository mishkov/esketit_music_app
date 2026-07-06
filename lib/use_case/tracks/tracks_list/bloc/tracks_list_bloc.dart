import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/shared/snapshot.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TracksListEvent extends Equatable {}

final class LoadMoreTracks extends TracksListEvent {
  @override
  List<Object?> get props => [];
}

class TracksListBloc extends Bloc<TracksListEvent, TracksListState> {
  final TracksStorage _tracksStorage;
  final ErrorReporter _errorReporter;

  TracksListBloc({
    required TracksListState initialState,
    required TracksStorage tracksStorage,
    required ErrorReporter errorReporter,
  }) : _tracksStorage = tracksStorage,
       _errorReporter = errorReporter,
       super(initialState) {
    on<LoadMoreTracks>((event, emit) async {
      try {
        emit(
          state.copyWith(
            tracks: state.tracks
                .map((track) => Snapshot.loading(track.data))
                .toList(growable: false),
          ),
        );

        final tracks = await _tracksStorage.getTracks(
          tracksPerPage: state.tracksPerPage,
          lastFetchedTrack: state.tracks.lastOrNull?.data,
        );

        emit(
          state.copyWith(
            tracks: [
              ...state.tracks.map((track) => Snapshot.done(track.data)),
              ...tracks.map(Snapshot.done),
            ],
          ),
        );
      } catch (error, stackTrace) {
        // TODO: emit error tracks.

        await _errorReporter.reportError(
          AppError(
            'Failed to load tracks list',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
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
