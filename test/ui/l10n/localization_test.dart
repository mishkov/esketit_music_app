import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
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
  testWidgets('catalog screen renders Russian localized search copy', (
    tester,
  ) async {
    final harness = _CatalogLocalizationHarness(
      searchResponses: {
        'пусто': {
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

    await tester.pumpWidget(harness.widget(const Locale('ru')));

    expect(find.text('Искать авторов, альбомы, треки'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'пусто');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump();

    expect(find.text('По запросу "пусто" ничего не найдено.'), findsOneWidget);
  });

  testWidgets('playlist editor renders Russian localized defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => const PlaylistEditorDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Новый плейлист'), findsOneWidget);
    expect(find.text('Название'), findsOneWidget);
    expect(find.text('Описание'), findsOneWidget);
    expect(find.text('URL или путь к обложке'), findsOneWidget);
    expect(find.text('Видимость'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Создать'), findsOneWidget);
  });
}

class _CatalogLocalizationHarness {
  factory _CatalogLocalizationHarness({
    required Map<String, Map<int, PaginatedCatalogSearchResults>>
    searchResponses,
  }) {
    final catalogStorage = _FakeCatalogStorage(
      searchResponses: searchResponses,
    );
    final player = _FakeAudioPlayer();
    final errorReporter = _FakeErrorReporter();
    final playlistsStorage = _FakePlaylistsStorage();

    return _CatalogLocalizationHarness._(
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

  const _CatalogLocalizationHarness._({
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

  Widget widget(Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePlaylist({required int playlistId}) {
    throw UnimplementedError();
  }

  @override
  Future<Playlist> getPlaylist({required int playlistId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Playlist>> getPlaylists() async => const [];

  @override
  Future<List<Track>> getPlaylistTracks({required int playlistId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> addTrackToFavorites({required int trackId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeTrackFromFavorites({required int trackId}) {
    throw UnimplementedError();
  }

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
