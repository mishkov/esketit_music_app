import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('query change resets search page to 1', () async {
    final bloc = CatalogBloc(
      initialState: const CatalogState(
        authors: [],
        isLoadingAuthors: false,
        authorsErrorMessage: null,
        albumsByAuthorId: {},
        loadingAuthorIds: {},
        authorAlbumsErrorMessages: {},
        tracksByAlbumId: {},
        loadingAlbumIds: {},
        albumTracksErrorMessages: {},
        searchQuery: 'old query',
        searchPage: 2,
        searchPageSize: CatalogBloc.searchPageSize,
        searchResults: null,
        isLoadingSearch: false,
        searchErrorMessage: null,
      ),
      catalogStorage: _FakeCatalogStorage(),
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(CatalogSearchQueryChanged('new query'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.searchQuery, 'new query');
    expect(bloc.state.searchPage, 1);

    await bloc.close();
  });
}

class _FakeCatalogStorage implements CatalogStorage {
  @override
  Future<List<Author>> getPublishedAuthors() async => const [];

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({
    required int authorId,
  }) async => const [];

  @override
  Future<List<Track>> getAlbumTracks({required Album album}) async => const [];

  @override
  Future<PaginatedCatalogSearchResults> search({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    throw UnimplementedError();
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
