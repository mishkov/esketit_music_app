import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/albums/album_details/bloc/album_details_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final album = _album(42);

  blocTest<AlbumDetailsBloc, AlbumDetailsState>(
    'loads a directly addressed album',
    build: () => AlbumDetailsBloc(
      initialState: _initialState(),
      catalogStorage: _FakeCatalogStorage(album: album),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(const LoadAlbumDetails(42)),
    expect: () => [
      const AlbumDetailsState(
        albumId: 42,
        album: null,
        isLoading: true,
        error: null,
      ),
      AlbumDetailsState(
        albumId: 42,
        album: album,
        isLoading: false,
        error: null,
      ),
    ],
  );

  blocTest<AlbumDetailsBloc, AlbumDetailsState>(
    'keeps a missing directly addressed album distinct from a load error',
    build: () => AlbumDetailsBloc(
      initialState: _initialState(),
      catalogStorage: const _FakeCatalogStorage(album: null),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(const LoadAlbumDetails(42)),
    expect: () => const [
      AlbumDetailsState(albumId: 42, album: null, isLoading: true, error: null),
      AlbumDetailsState(
        albumId: 42,
        album: null,
        isLoading: false,
        error: null,
      ),
    ],
  );
}

AlbumDetailsState _initialState() {
  return const AlbumDetailsState(
    albumId: 42,
    album: null,
    isLoading: false,
    error: null,
  );
}

class _FakeCatalogStorage implements CatalogStorage {
  const _FakeCatalogStorage({required this.album});

  final Album? album;

  @override
  Future<Album?> getAlbum({required int albumId}) async => album;

  @override
  Future<List<Track>> getAlbumTracks({required Album album}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({required int authorId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Author>> getPublishedAuthors() {
    throw UnimplementedError();
  }

  @override
  Future<PaginatedCatalogSearchResults> search({
    required String query,
    required int page,
    required int pageSize,
  }) {
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

Album _album(int id) {
  return Album(
    id: id,
    title: 'Album $id',
    coverImage: _FakeFile(),
    authorIds: const [1],
    releaseDate: null,
    isPublished: true,
    trackIds: const [],
    additionalInfo: const [],
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
