import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_queries_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  blocTest<CatalogBloc, CatalogState>(
    'query change resets search page to 1',
    build: () => CatalogBloc(
      initialState: _catalogState(searchQuery: 'old query', searchPage: 2),
      catalogStorage: _FakeCatalogStorage(),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(CatalogSearchQueryChanged('new query')),
    expect: () => [_catalogState(searchQuery: 'new query', searchPage: 1)],
  );

  blocTest<CatalogBloc, CatalogState>(
    'published albums by author are sorted from new to old',
    build: () => CatalogBloc(
      initialState: _catalogState(),
      catalogStorage: _FakeCatalogStorage(
        albumsByAuthorId: {
          _author.id: [_oldestAlbum, _undatedAlbum, _newestAlbum],
        },
      ),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(LoadPublishedAlbumsByAuthor(_author)),
    expect: () => [
      _catalogState(loadingAuthorIds: {_author.id}),
      _catalogState(
        albumsByAuthorId: {
          _author.id: [_newestAlbum, _oldestAlbum, _undatedAlbum],
        },
      ),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'loads recent search queries into state',
    build: () => CatalogBloc(
      initialState: _catalogState(),
      catalogStorage: _FakeCatalogStorage(),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(
        recentSearchQueries: const ['drake', 'metro'],
      ),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(LoadRecentSearchQueries()),
    expect: () => [
      _catalogState(recentSearchQueries: const ['drake', 'metro']),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'saves recent search query after successful first-page search with results',
    build: () => CatalogBloc(
      initialState: _catalogState(searchQuery: 'future'),
      catalogStorage: _FakeCatalogStorage(
        searchResults: PaginatedCatalogSearchResults(
          items: const [_searchResultItem],
          page: 1,
          pageSize: CatalogBloc.searchPageSize,
          totalItems: 1,
          totalPages: 1,
        ),
      ),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(
        recentSearchQueries: const ['metro'],
      ),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(LoadCatalogSearchResults()),
    expect: () => [
      _catalogState(searchQuery: 'future', isLoadingSearch: true),
      _catalogState(
        searchQuery: 'future',
        recentSearchQueries: const ['future', 'metro'],
        searchResults: PaginatedCatalogSearchResults(
          items: const [_searchResultItem],
          page: 1,
          pageSize: CatalogBloc.searchPageSize,
          totalItems: 1,
          totalPages: 1,
        ),
      ),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'does not save recent search query when first-page search returns no results',
    build: () => CatalogBloc(
      initialState: _catalogState(
        searchQuery: 'missing',
        recentSearchQueries: const ['metro'],
      ),
      catalogStorage: _FakeCatalogStorage(
        searchResults: const PaginatedCatalogSearchResults(
          items: [],
          page: 1,
          pageSize: CatalogBloc.searchPageSize,
          totalItems: 0,
          totalPages: 0,
        ),
      ),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(
        recentSearchQueries: const ['metro'],
      ),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(LoadCatalogSearchResults()),
    expect: () => [
      _catalogState(
        searchQuery: 'missing',
        recentSearchQueries: const ['metro'],
        isLoadingSearch: true,
      ),
      _catalogState(
        searchQuery: 'missing',
        recentSearchQueries: const ['metro'],
        searchResults: const PaginatedCatalogSearchResults(
          items: [],
          page: 1,
          pageSize: CatalogBloc.searchPageSize,
          totalItems: 0,
          totalPages: 0,
        ),
      ),
    ],
  );
}

class _FakeCatalogStorage implements CatalogStorage {
  _FakeCatalogStorage({this.albumsByAuthorId = const {}, this.searchResults});

  final Map<int, List<Album>> albumsByAuthorId;
  final PaginatedCatalogSearchResults? searchResults;

  @override
  Future<List<Author>> getPublishedAuthors() async => const [];

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({
    required int authorId,
  }) async => albumsByAuthorId[authorId] ?? const [];

  @override
  Future<List<Track>> getAlbumTracks({required Album album}) async => const [];

  @override
  Future<PaginatedCatalogSearchResults> search({
    required String query,
    required int page,
    required int pageSize,
  }) async => searchResults!;
}

class _FakeRecentSearchQueriesStorage implements RecentSearchQueriesStorage {
  _FakeRecentSearchQueriesStorage({this.recentSearchQueries = const []});

  List<String> recentSearchQueries;

  @override
  Future<List<String>> getRecentSearchQueries() async => recentSearchQueries;

  @override
  Future<List<String>> saveRecentSearchQuery(String query) async {
    recentSearchQueries = [
      query,
      ...recentSearchQueries.where((currentQuery) => currentQuery != query),
    ].take(10).toList(growable: false);

    return recentSearchQueries;
  }
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

CatalogState _catalogState({
  List<Author> authors = const [],
  bool isLoadingAuthors = false,
  String? authorsErrorMessage,
  Map<int, List<Album>> albumsByAuthorId = const {},
  Set<int> loadingAuthorIds = const {},
  Map<int, String> authorAlbumsErrorMessages = const {},
  Map<int, List<Track>> tracksByAlbumId = const {},
  Set<int> loadingAlbumIds = const {},
  Map<int, String> albumTracksErrorMessages = const {},
  String searchQuery = '',
  List<String> recentSearchQueries = const [],
  int searchPage = 1,
  int searchPageSize = CatalogBloc.searchPageSize,
  PaginatedCatalogSearchResults? searchResults,
  bool isLoadingSearch = false,
  String? searchErrorMessage,
}) {
  return CatalogState(
    authors: authors,
    isLoadingAuthors: isLoadingAuthors,
    authorsErrorMessage: authorsErrorMessage,
    albumsByAuthorId: albumsByAuthorId,
    loadingAuthorIds: loadingAuthorIds,
    authorAlbumsErrorMessages: authorAlbumsErrorMessages,
    tracksByAlbumId: tracksByAlbumId,
    loadingAlbumIds: loadingAlbumIds,
    albumTracksErrorMessages: albumTracksErrorMessages,
    searchQuery: searchQuery,
    recentSearchQueries: recentSearchQueries,
    searchPage: searchPage,
    searchPageSize: searchPageSize,
    searchResults: searchResults,
    isLoadingSearch: isLoadingSearch,
    searchErrorMessage: searchErrorMessage,
  );
}

const _author = Author(id: 7, currentName: 'Author', photos: []);

final _newestAlbum = _album(id: 1, releaseDate: DateTime(2024, 6, 1));
final _oldestAlbum = _album(id: 2, releaseDate: DateTime(2020, 1, 1));
final _undatedAlbum = _album(id: 3, releaseDate: null);
const _searchResultItem = CatalogSearchResultItem.author(_author);

Album _album({required int id, required DateTime? releaseDate}) {
  return Album(
    id: id,
    title: 'Album $id',
    coverImage: _FakeFile(),
    authorIds: [_author.id],
    releaseDate: releaseDate,
    isPublished: true,
    trackIds: const [],
    additionalInfo: const [],
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
