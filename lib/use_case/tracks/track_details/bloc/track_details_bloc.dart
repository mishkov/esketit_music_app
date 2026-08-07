import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class TrackDetailsEvent extends Equatable {
  const TrackDetailsEvent();
}

final class LoadTrackDetails extends TrackDetailsEvent {
  const LoadTrackDetails(this.trackId);

  final int trackId;

  @override
  List<Object?> get props => [trackId];
}

class TrackDetailsBloc extends Bloc<TrackDetailsEvent, TrackDetailsState> {
  TrackDetailsBloc({
    required TrackDetailsState initialState,
    required TracksStorage tracksStorage,
    required ErrorReporter errorReporter,
  }) : _tracksStorage = tracksStorage,
       _errorReporter = errorReporter,
       super(initialState) {
    on<LoadTrackDetails>(_onLoadTrackDetails);
  }

  final TracksStorage _tracksStorage;
  final ErrorReporter _errorReporter;

  Future<void> _onLoadTrackDetails(
    LoadTrackDetails event,
    Emitter<TrackDetailsState> emit,
  ) async {
    emit(
      TrackDetailsState(
        trackId: event.trackId,
        track: null,
        isLoading: true,
        error: null,
      ),
    );

    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Open track URL',
          category: Category.navigation,
          data: {'trackId': event.trackId},
        ),
      );
      final track = await _tracksStorage.getTrack(trackId: event.trackId);

      emit(
        TrackDetailsState(
          trackId: event.trackId,
          track: track,
          isLoading: false,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      final appError = AppError(
        'Failed to load track ${event.trackId} from URL',
        cause: error,
        stackTrace: stackTrace,
      );
      emit(
        TrackDetailsState(
          trackId: event.trackId,
          track: null,
          isLoading: false,
          error: appError,
        ),
      );
      await _errorReporter.reportError(appError);
    }
  }
}

class TrackDetailsState extends Equatable {
  const TrackDetailsState({
    required this.trackId,
    required this.track,
    required this.isLoading,
    required this.error,
  });

  final int trackId;
  final Track? track;
  final bool isLoading;
  final AppError? error;

  @override
  List<Object?> get props => [trackId, track, isLoading, error];
}
