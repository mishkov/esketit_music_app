import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders mixed result types from search', (tester) async {
    final harness = _CatalogTestHarness(
      searchResponses: {
        'mix': {
          1: PaginatedCatalogSearchResults(
            items: [
              CatalogSearchResultItem.author(_author(name: 'Author Result')),
              CatalogSearchResultItem.album(_album(title: 'Album Result')),
              CatalogSearchResultItem.track(_track(name: 'Track Result')),
            ],
            page: 1,
            pageSize: CatalogBloc.searchPageSize,
            totalItems: 3,
            totalPages: 1,
          ),
        },
      },
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.enterText(find.byType(TextField), 'mix');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump();

    expect(find.text('Author Result'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Album Result'), findsOneWidget);
    expect(find.text('Track Result'), findsOneWidget);
  });

  testWidgets('shows empty state when search returns no items', (tester) async {
    final harness = _CatalogTestHarness(
      searchResponses: {
        'empty': {
          1: const PaginatedCatalogSearchResults(
            items: [],
            page: 1,
            pageSize: CatalogBloc.searchPageSize,
            totalItems: 0,
            totalPages: 0,
          ),
        },
      },
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.enterText(find.byType(TextField), 'empty');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump();

    expect(find.text('No results found for "empty".'), findsOneWidget);
  });

  testWidgets('loads next page when scrolled near the bottom', (tester) async {
    final harness = _CatalogTestHarness(
      searchResponses: {
        'paged': {
          1: PaginatedCatalogSearchResults(
            items: List.generate(
              10,
              (index) => CatalogSearchResultItem.author(
                _author(name: index == 0 ? 'Page One' : 'Page One $index'),
              ),
            ),
            page: 1,
            pageSize: CatalogBloc.searchPageSize,
            totalItems: 11,
            totalPages: 2,
          ),
          2: PaginatedCatalogSearchResults(
            items: [CatalogSearchResultItem.author(_author(name: 'Page Two'))],
            page: 2,
            pageSize: CatalogBloc.searchPageSize,
            totalItems: 11,
            totalPages: 2,
          ),
        },
      },
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.enterText(find.byType(TextField), 'paged');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump();

    expect(find.text('Page One'), findsOneWidget);
    expect(find.text('Page Two'), findsNothing);

    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, -1200),
      2000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Page Two'), findsOneWidget);
    expect(find.text('End of results'), findsOneWidget);
    expect(harness.catalogStorage.searchCalls, [
      ('paged', 1, CatalogBloc.searchPageSize),
      ('paged', 2, CatalogBloc.searchPageSize),
    ]);
  });
}

class _CatalogTestHarness {
  factory _CatalogTestHarness({
    required Map<String, Map<int, PaginatedCatalogSearchResults>>
    searchResponses,
  }) {
    final catalogStorage = _FakeCatalogStorage(
      searchResponses: searchResponses,
    );
    final player = _FakeAudioPlayer();
    final errorReporter = _FakeErrorReporter();
    final playlistsStorage = _FakePlaylistsStorage();

    return _CatalogTestHarness._(
      catalogStorage: catalogStorage,
      player: player,
      errorReporter: errorReporter,
      playlistsStorage: playlistsStorage,
      catalogBloc: CatalogBloc(
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
          searchQuery: '',
          searchPage: 1,
          searchPageSize: CatalogBloc.searchPageSize,
          searchResults: null,
          isLoadingSearch: false,
          searchErrorMessage: null,
        ),
        catalogStorage: catalogStorage,
        errorReporter: errorReporter,
      ),
      playerBloc: PlayerBloc(
        initialState: const PlayerState(selectedTrack: null, isPlaying: false),
        player: player,
        errorReporter: errorReporter,
      ),
      playlistsBloc: PlaylistsBloc(
        playlistsStorage: playlistsStorage,
        errorReporter: errorReporter,
      ),
    );
  }

  const _CatalogTestHarness._({
    required this.catalogStorage,
    required this.player,
    required this.errorReporter,
    required this.playlistsStorage,
    required this.catalogBloc,
    required this.playerBloc,
    required this.playlistsBloc,
  });

  final _FakeCatalogStorage catalogStorage;
  final _FakeAudioPlayer player;
  final _FakeErrorReporter errorReporter;
  final _FakePlaylistsStorage playlistsStorage;
  final CatalogBloc catalogBloc;
  final PlayerBloc playerBloc;
  final PlaylistsBloc playlistsBloc;

  Widget get widget => MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<CatalogBloc>.value(value: catalogBloc),
        BlocProvider<PlayerBloc>.value(value: playerBloc),
        BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
      ],
      child: const Scaffold(body: CatalogScreen()),
    ),
  );

  Future<void> dispose() async {
    await catalogBloc.close();
    await playerBloc.close();
    await playlistsBloc.close();
    await player.dispose();
  }
}

class _FakeCatalogStorage implements CatalogStorage {
  _FakeCatalogStorage({required this.searchResponses});

  final Map<String, Map<int, PaginatedCatalogSearchResults>> searchResponses;
  final List<(String, int, int)> searchCalls = <(String, int, int)>[];

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
    searchCalls.add((query, page, pageSize));

    return searchResponses[query]![page]!;
  }
}

class _FakeAudioPlayer implements AudioPlayer {
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();

  @override
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {}

  @override
  Future<void> togglePlay() async {}

  @override
  Future<void> dispose() async {
    await _isPlayingController.close();
    await _currentTrackController.close();
  }
}

class _FakePlaylistsStorage implements PlaylistsStorage {
  @override
  Future<void> addTrackToFavorites({required int trackId}) async {}

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) async {}

  @override
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePlaylist({required int playlistId}) async {}

  @override
  Future<Playlist> getPlaylist({required int playlistId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Playlist>> getPlaylists() async => const [];

  @override
  Future<List<Track>> getPlaylistTracks({required int playlistId}) async =>
      const [];

  @override
  Future<void> removeTrackFromFavorites({required int trackId}) async {}

  @override
  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  }) async {}

  @override
  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  }) async {}

  @override
  Future<Playlist> updatePlaylist({
    required int playlistId,
    required PlaylistUpsertInput input,
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

Author _author({required String name}) {
  return Author(id: name.hashCode, currentName: name, photos: const []);
}

Album _album({required String title}) {
  return Album(
    id: title.hashCode,
    title: title,
    coverImage: HttpFile(uri: Uri()),
    authorIds: const [1],
    releaseDate: DateTime(2024, 1, 1),
    isPublished: true,
    trackIds: const [],
    additionalInfo: const [],
  );
}

Track _track({required String name}) {
  return Track(
    id: name.hashCode,
    name: name,
    authors: [_author(name: 'Track Author')],
    addionalInfo: [TextTrackInfo(title: 'Mood', text: 'Warm')],
    file: HttpFile(uri: Uri()),
    image: HttpFile(uri: Uri()),
    isFavorite: false,
    isAvailable: true,
  );
}
