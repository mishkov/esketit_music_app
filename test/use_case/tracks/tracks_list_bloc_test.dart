import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sortedTracksStorage = _FakeTracksStorage(
    pages: {
      1: PaginatedTracks(
        items: [_track(1)],
        page: 1,
        pageSize: 6,
        totalItems: 1,
        totalPages: 1,
      ),
    },
  );

  blocTest<TracksListBloc, TracksListState>(
    'loads first page with added date descending sort',
    build: () => TracksListBloc(
      initialState: _tracksListState(pageSize: 6),
      tracksStorage: sortedTracksStorage,
      errorReporter: _FakeErrorReporter(),
      sort: TracksSort.addedAt,
      order: TracksSortOrder.descending,
    ),
    act: (bloc) => bloc.add(LoadMoreTracks()),
    expect: () => [
      _tracksListState(pageSize: 6, isLoading: true),
      _tracksListState(
        tracks: [_track(1)],
        page: 1,
        pageSize: 6,
        totalItems: 1,
        totalPages: 1,
      ),
    ],
    verify: (_) {
      expect(sortedTracksStorage.calls, hasLength(1));
      expect(sortedTracksStorage.calls.single.page, 1);
      expect(sortedTracksStorage.calls.single.pageSize, 6);
      expect(sortedTracksStorage.calls.single.sort, TracksSort.addedAt);
      expect(
        sortedTracksStorage.calls.single.order,
        TracksSortOrder.descending,
      );
    },
  );

  blocTest<TracksListBloc, TracksListState>(
    'appends next page and stops after last page',
    build: () => TracksListBloc(
      initialState: _tracksListState(pageSize: 2),
      tracksStorage: _FakeTracksStorage(
        pages: {
          1: PaginatedTracks(
            items: [_track(1), _track(2)],
            page: 1,
            pageSize: 2,
            totalItems: 3,
            totalPages: 2,
          ),
          2: PaginatedTracks(
            items: [_track(3)],
            page: 2,
            pageSize: 2,
            totalItems: 3,
            totalPages: 2,
          ),
        },
      ),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) {
      bloc
        ..add(LoadMoreTracks())
        ..add(LoadMoreTracks())
        ..add(LoadMoreTracks());
    },
    expect: () => [
      _tracksListState(pageSize: 2, isLoading: true),
      _tracksListState(
        tracks: [_track(1), _track(2)],
        page: 1,
        pageSize: 2,
        totalItems: 3,
        totalPages: 2,
      ),
      _tracksListState(
        tracks: [_track(1), _track(2)],
        page: 1,
        pageSize: 2,
        totalItems: 3,
        totalPages: 2,
        isLoading: true,
      ),
      _tracksListState(
        tracks: [_track(1), _track(2), _track(3)],
        page: 2,
        pageSize: 2,
        totalItems: 3,
        totalPages: 2,
      ),
    ],
  );
}

class _FakeTracksStorage implements TracksStorage {
  _FakeTracksStorage({required this.pages});

  final Map<int, PaginatedTracks> pages;
  final List<_GetTracksCall> calls = [];

  @override
  Future<PaginatedTracks> getTracks({
    required int page,
    required int pageSize,
    TracksSort sort = TracksSort.id,
    TracksSortOrder order = TracksSortOrder.ascending,
  }) async {
    calls.add(
      _GetTracksCall(page: page, pageSize: pageSize, sort: sort, order: order),
    );

    return pages[page] ??
        PaginatedTracks(
          items: const [],
          page: page,
          pageSize: pageSize,
          totalItems: 0,
          totalPages: 0,
        );
  }
}

class _GetTracksCall {
  final int page;
  final int pageSize;
  final TracksSort sort;
  final TracksSortOrder order;

  const _GetTracksCall({
    required this.page,
    required this.pageSize,
    required this.sort,
    required this.order,
  });
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

TracksListState _tracksListState({
  List<Track> tracks = const [],
  int page = 0,
  int pageSize = 20,
  int totalItems = 0,
  int totalPages = 1,
  bool isLoading = false,
  AppError? error,
}) {
  return TracksListState(
    tracks: tracks,
    page: page,
    pageSize: pageSize,
    totalItems: totalItems,
    totalPages: totalPages,
    isLoading: isLoading,
    error: error,
  );
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Artist', photos: [])],
    addionalInfo: const [],
    file: _FakeFile(),
    image: _FakeFile(),
    isFavorite: false,
    isAvailable: true,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
