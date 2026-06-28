import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen.dart';
import 'package:esketit_music_app/ui/catalog/recent_search_queries_section.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_queries_storage.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects a recent search query and starts searching', (
    tester,
  ) async {
    final catalogStorage = _FakeCatalogStorage();
    final recentSearchQueriesStorage = _FakeRecentSearchQueriesStorage(
      recentSearchQueries: const ['metro'],
    );
    final catalogBloc = _createCatalogBloc(
      catalogStorage: catalogStorage,
      recentSearchQueriesStorage: recentSearchQueriesStorage,
    );
    final playerBloc = PlayerBloc(
      initialState: const PlayerState(selectedTrack: null, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: _FakeErrorReporter(),
    );

    addTearDown(catalogBloc.close);
    addTearDown(playerBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CatalogBloc>.value(value: catalogBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CatalogScreen()),
        ),
      ),
    );

    catalogBloc.add(LoadRecentSearchQueries());
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      find.ancestor(
        of: find.byType(RecentSearchQueriesSection),
        matching: find.byType(TextFieldTapRegion),
      ),
      findsOneWidget,
    );
    expect(find.text('metro'), findsOneWidget);

    await tester.tap(find.text('metro'));
    await tester.pump();
    await tester.pump();

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.controller!.text, 'metro');
    expect(catalogStorage.searchQueries, ['metro']);
    expect(find.text('Metro Boomin'), findsOneWidget);
  });
}

CatalogBloc _createCatalogBloc({
  required CatalogStorage catalogStorage,
  required RecentSearchQueriesStorage recentSearchQueriesStorage,
}) {
  return CatalogBloc(
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
      recentSearchQueries: [],
      searchPage: 1,
      searchPageSize: CatalogBloc.searchPageSize,
      searchResults: null,
      isLoadingSearch: false,
      searchErrorMessage: null,
    ),
    catalogStorage: catalogStorage,
    recentSearchQueriesStorage: recentSearchQueriesStorage,
    errorReporter: _FakeErrorReporter(),
  );
}

class _FakeCatalogStorage implements CatalogStorage {
  final List<String> searchQueries = [];

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
    searchQueries.add(query);

    return const PaginatedCatalogSearchResults(
      items: [
        CatalogSearchResultItem.author(
          Author(id: 1, currentName: 'Metro Boomin', photos: []),
        ),
      ],
      page: 1,
      pageSize: CatalogBloc.searchPageSize,
      totalItems: 1,
      totalPages: 1,
    );
  }
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
    ];

    return recentSearchQueries;
  }
}

class _FakeAudioPlayer implements AudioPlayer {
  @override
  Duration get currentPosition => Duration.zero;

  @override
  Stream<Track?> get currentTrackStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get hasNextTrackStream => const Stream.empty();

  @override
  Stream<bool> get hasPreviousTrackStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Future<void> appendToQueue(List<Track> tracks) async {}

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> skipToNextTrack() async {}

  @override
  Future<void> skipToPreviousTrack() async {}

  @override
  Future<void> togglePlay() async {}
}

class _FakeAutoplayStorage implements AutoplayStorage {
  @override
  Future<AutoplayTracksBatch> getNextTracks({
    required AutoplayContext context,
    required int count,
    required List<int> recentTrackIds,
    required List<int> excludedTrackIds,
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
