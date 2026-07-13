import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
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
  final TracksSort _sort;
  final TracksSortOrder _order;

  TracksListBloc({
    required TracksListState initialState,
    required TracksStorage tracksStorage,
    required ErrorReporter errorReporter,
    TracksSort sort = TracksSort.id,
    TracksSortOrder order = TracksSortOrder.ascending,
  }) : _tracksStorage = tracksStorage,
       _errorReporter = errorReporter,
       _sort = sort,
       _order = order,
       super(initialState) {
    on<LoadMoreTracks>((event, emit) async {
      if (state.isLoading || !state.hasMoreTracks) {
        return;
      }

      final requestedPage = state.page + 1;

      try {
        emit(state.copyWith(isLoading: true, clearError: true));

        await _errorReporter.addBreadcrumb(
          Breadcrumb(
            message: 'Loading tracks page',
            category: Category.http,
            data: {
              'page': requestedPage,
              'pageSize': state.pageSize,
              'sort': _sort.name,
              'order': _order.name,
            },
          ),
        );

        final tracksPage = await _tracksStorage.getTracks(
          page: requestedPage,
          pageSize: state.pageSize,
          sort: _sort,
          order: _order,
        );

        emit(
          state.copyWith(
            tracks: [...state.tracks, ...tracksPage.items],
            page: tracksPage.page,
            pageSize: tracksPage.pageSize,
            totalItems: tracksPage.totalItems,
            totalPages: tracksPage.totalPages,
            isLoading: false,
            clearError: true,
          ),
        );
      } catch (error, stackTrace) {
        final appError = AppError(
          'Failed to load tracks page $requestedPage',
          cause: error,
          stackTrace: stackTrace,
        );

        emit(state.copyWith(isLoading: false, error: appError));

        await _errorReporter.reportError(appError);
      }
    });
  }
}

class TracksListState extends Equatable {
  final List<Track> tracks;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool isLoading;
  final AppError? error;

  const TracksListState({
    required this.tracks,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.isLoading,
    required this.error,
  });

  TracksListState copyWith({
    List<Track>? tracks,
    int? page,
    int? pageSize,
    int? totalItems,
    int? totalPages,
    bool? isLoading,
    AppError? error,
    bool clearError = false,
  }) {
    return TracksListState(
      tracks: tracks ?? this.tracks,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    tracks,
    page,
    pageSize,
    totalItems,
    totalPages,
    isLoading,
    error,
  ];

  bool get hasMoreTracks => page == 0 || page < totalPages;
}
