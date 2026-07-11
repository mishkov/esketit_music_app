import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/tracks/track_screen.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_queries_storage.dart';
import 'package:esketit_music_app/use_case/lyrics/bloc/lyrics_bloc.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adds selected track to playlist from track screen menu', (
    tester,
  ) async {
    final track = _track(1);
    final playlist = _playlist(7, name: 'Road');
    final errorReporter = _FakeErrorReporter();
    final authBloc = AuthBloc(
      authRepository: _FakeAuthRepository(),
      errorReporter: errorReporter,
    )..add(const AuthSessionRestoreRequested());
    final playlistsStorage = _FakePlaylistsStorage(playlists: [playlist]);
    final playlistsBloc = PlaylistsBloc(
      playlistsStorage: playlistsStorage,
      errorReporter: errorReporter,
    )..add(const LoadPlaylists());
    final playerBloc = PlayerBloc(
      initialState: PlayerState(selectedTrack: track, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: errorReporter,
    );
    final catalogBloc = CatalogBloc(
      initialState: _emptyCatalogState(),
      catalogStorage: _FakeCatalogStorage(),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(),
      errorReporter: errorReporter,
    );
    final lyricsBloc = LyricsBloc(lyricsStorage: _FakeLyricsStorage());

    addTearDown(authBloc.close);
    addTearDown(playlistsBloc.close);
    addTearDown(playerBloc.close);
    addTearDown(catalogBloc.close);
    addTearDown(lyricsBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
          BlocProvider<CatalogBloc>.value(value: catalogBloc),
          BlocProvider<LyricsBloc>.value(value: lyricsBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrackScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to playlists'));
    await tester.pumpAndSettle();

    expect(find.text('Road'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(playlistsStorage.addedTrackIds, [track.id]);
    expect(playlistsStorage.addedTrackPlaylistIds, [playlist.id]);
  });

  testWidgets('creates playlist while adding selected track to playlists', (
    tester,
  ) async {
    final track = _track(1);
    final existingPlaylist = _playlist(7, name: 'Gym');
    final errorReporter = _FakeErrorReporter();
    final authBloc = AuthBloc(
      authRepository: _FakeAuthRepository(),
      errorReporter: errorReporter,
    )..add(const AuthSessionRestoreRequested());
    final playlistsStorage = _FakePlaylistsStorage(
      playlists: [existingPlaylist],
    );
    final playlistsBloc = PlaylistsBloc(
      playlistsStorage: playlistsStorage,
      errorReporter: errorReporter,
    )..add(const LoadPlaylists());
    final playerBloc = PlayerBloc(
      initialState: PlayerState(selectedTrack: track, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: errorReporter,
    );
    final catalogBloc = CatalogBloc(
      initialState: _emptyCatalogState(),
      catalogStorage: _FakeCatalogStorage(),
      recentSearchQueriesStorage: _FakeRecentSearchQueriesStorage(),
      errorReporter: errorReporter,
    );
    final lyricsBloc = LyricsBloc(lyricsStorage: _FakeLyricsStorage());

    addTearDown(authBloc.close);
    addTearDown(playlistsBloc.close);
    addTearDown(playerBloc.close);
    addTearDown(catalogBloc.close);
    addTearDown(lyricsBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
          BlocProvider<CatalogBloc>.value(value: catalogBloc),
          BlocProvider<LyricsBloc>.value(value: lyricsBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrackScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to playlists'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'New playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Name'), 'Road');
    await tester.enterText(
      find.bySemanticsLabel('Description'),
      'Driving playlist',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    final createdPlaylistTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Road'),
    );
    final existingPlaylistTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Gym'),
    );
    expect(createdPlaylistTile.value, isTrue);
    expect(existingPlaylistTile.value, isFalse);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Gym'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(playlistsStorage.createdPlaylistNames, ['Road']);
    expect(playlistsStorage.addedTrackIds, [track.id]);
    expect(playlistsStorage.addedTrackPlaylistIds, unorderedEquals([2, 7]));
  });
}

class _FakeAuthRepository implements AuthRepository {
  final AuthSession _session = AuthSession(
    user: AppUser(
      id: 1,
      email: 'listener@example.com',
      role: AppUserRole.listener,
      createdAt: DateTime.utc(2026),
    ),
    accessToken: 'access',
    accessTokenExpiresAt: DateTime.utc(2027),
    refreshToken: 'refresh',
    refreshTokenExpiresAt: DateTime.utc(2027),
  );

  @override
  Future<AuthSession?> refreshSession({bool forceRefresh = false}) async =>
      _session;

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<void> signOut() async {}
}

class _FakeCatalogStorage implements CatalogStorage {
  @override
  Future<List<Track>> getAlbumTracks({required Album album}) async => const [];

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({
    required int authorId,
  }) async {
    return const [];
  }

  @override
  Future<List<Author>> getPublishedAuthors() async => const [];

  @override
  Future<PaginatedCatalogSearchResults> search({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    return PaginatedCatalogSearchResults(
      items: const [],
      page: page,
      pageSize: pageSize,
      totalItems: 0,
      totalPages: 0,
    );
  }
}

class _FakeRecentSearchQueriesStorage implements RecentSearchQueriesStorage {
  @override
  Future<List<String>> getRecentSearchQueries() async => const [];

  @override
  Future<List<String>> saveRecentSearchQuery(String query) async => [query];
}

class _FakeLyricsStorage implements LyricsStorage {
  @override
  Future<TrackLyrics?> getTrackLyrics({required int trackId}) async => null;
}

class _FakePlaylistsStorage implements PlaylistsStorage {
  _FakePlaylistsStorage({required List<Playlist> playlists})
    : _playlists = playlists;

  List<Playlist> _playlists;
  final List<int> addedTrackIds = <int>[];
  final List<int> addedTrackPlaylistIds = <int>[];
  final List<String> createdPlaylistNames = <String>[];

  @override
  Future<List<Playlist>> getPlaylists() async => _playlists;

  @override
  Future<void> addTrackToFavorites({required int trackId}) async {}

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) async {
    addedTrackIds.add(trackId);
    addedTrackPlaylistIds.addAll(playlistIds);
  }

  @override
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) async {
    createdPlaylistNames.add(input.name);
    final playlist = Playlist(
      id: _playlists.length + 1,
      userId: 1,
      name: input.name,
      description: input.description,
      coverImagePath: input.coverImagePath,
      visibility: input.visibility,
      trackCount: 0,
      system: false,
      isFavorites: false,
    );
    _playlists = [..._playlists, playlist];

    return playlist;
  }

  @override
  Future<void> deletePlaylist({required int playlistId}) async {}

  @override
  Future<Playlist> getPlaylist({required int playlistId}) async =>
      _playlists.singleWhere((playlist) => playlist.id == playlistId);

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

  @override
  Future<Playlist> uploadPlaylistCover({
    required int playlistId,
    required PlaylistCoverUploadInput input,
  }) {
    throw UnimplementedError();
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

CatalogState _emptyCatalogState() {
  return const CatalogState(
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
    searchPage: 0,
    searchPageSize: CatalogBloc.searchPageSize,
    searchResults: null,
    isLoadingSearch: false,
    searchErrorMessage: null,
  );
}

Playlist _playlist(int id, {required String name}) {
  return Playlist(
    id: id,
    userId: 1,
    name: name,
    description: '',
    coverImagePath: '',
    visibility: PlaylistVisibility.private,
    trackCount: 0,
    system: false,
    isFavorites: false,
  );
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Author', photos: [])],
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
