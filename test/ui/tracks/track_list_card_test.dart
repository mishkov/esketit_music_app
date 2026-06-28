import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads playlists before showing add-to-playlists choices', (
    tester,
  ) async {
    final track = _track(1);
    final playlist = _playlist(7, name: 'Road');
    final playlistsStorage = _FakePlaylistsStorage();
    final authBloc = AuthBloc(
      authRepository: _FakeAuthRepository(),
      errorReporter: _FakeErrorReporter(),
    )..add(const AuthSessionRestoreRequested());
    final playlistsBloc = PlaylistsBloc(
      playlistsStorage: playlistsStorage,
      errorReporter: _FakeErrorReporter(),
    );
    final playerBloc = PlayerBloc(
      initialState: const PlayerState(selectedTrack: null, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: _FakeErrorReporter(),
    );

    addTearDown(authBloc.close);
    addTearDown(playlistsBloc.close);
    addTearDown(playerBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TrackListCard(track: track, queue: [track]),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.playlist_add_rounded));
    await tester.pump();

    expect(playlistsStorage.getPlaylistsCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Create a custom playlist first.'), findsNothing);

    playlistsStorage.completePlaylists([playlist]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Road'), findsOneWidget);
    expect(find.text('0 tracks'), findsOneWidget);
  });

  testWidgets('checks existing playlists and removes unchecked playlist', (
    tester,
  ) async {
    final track = _track(1);
    final playlist = _playlist(7, name: 'Road', trackCount: 1);
    final playlistsStorage = _FakePlaylistsStorage(
      playlists: [playlist],
      playlistTracksById: {
        playlist.id: [track],
      },
    );
    final authBloc = AuthBloc(
      authRepository: _FakeAuthRepository(),
      errorReporter: _FakeErrorReporter(),
    )..add(const AuthSessionRestoreRequested());
    final playlistsBloc = PlaylistsBloc(
      playlistsStorage: playlistsStorage,
      errorReporter: _FakeErrorReporter(),
    )..add(const LoadPlaylists());
    final playerBloc = PlayerBloc(
      initialState: const PlayerState(selectedTrack: null, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: _FakeErrorReporter(),
    );

    addTearDown(authBloc.close);
    addTearDown(playlistsBloc.close);
    addTearDown(playerBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TrackListCard(track: track, queue: [track]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.playlist_add_rounded));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(playlistsStorage.removedTrackPlaylistIds, [playlist.id]);
    expect(playlistsStorage.removedTrackIds, [track.id]);
  });

  testWidgets('shows save-to-downloads action when explicitly enabled', (
    tester,
  ) async {
    final track = _track(1).copyWith(
      file: HttpFile(uri: Uri.parse('https://example.com/audio/track.mp3')),
    );
    final playlistsBloc = PlaylistsBloc(
      playlistsStorage: _FakePlaylistsStorage(),
      errorReporter: _FakeErrorReporter(),
    );
    final playerBloc = PlayerBloc(
      initialState: const PlayerState(selectedTrack: null, isPlaying: false),
      player: _FakeAudioPlayer(),
      autoplayStorage: _FakeAutoplayStorage(),
      errorReporter: _FakeErrorReporter(),
    );
    final authBloc = AuthBloc(
      authRepository: _FakeAuthRepository(),
      errorReporter: _FakeErrorReporter(),
    )..add(const AuthSessionRestoreRequested());

    addTearDown(authBloc.close);
    addTearDown(playlistsBloc.close);
    addTearDown(playerBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<PlaylistsBloc>.value(value: playlistsBloc),
          BlocProvider<PlayerBloc>.value(value: playerBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TrackListCard(
              track: track,
              queue: [track],
              showSaveToDownloadsAction: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
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

class _FakePlaylistsStorage implements PlaylistsStorage {
  _FakePlaylistsStorage({
    List<Playlist> playlists = const [],
    Map<int, List<Track>> playlistTracksById = const {},
  }) : _playlists = playlists,
       _playlistTracksById = playlistTracksById;

  Completer<List<Playlist>>? _playlistsCompleter;
  List<Playlist> _playlists;
  final Map<int, List<Track>> _playlistTracksById;
  int getPlaylistsCallCount = 0;
  final List<int> removedTrackIds = <int>[];
  final List<int> removedTrackPlaylistIds = <int>[];

  void completePlaylists(List<Playlist> playlists) {
    _playlists = playlists;
    _playlistsCompleter?.complete(playlists);
  }

  @override
  Future<List<Playlist>> getPlaylists() {
    getPlaylistsCallCount++;
    if (_playlists.isNotEmpty) {
      return Future.value(_playlists);
    }

    final completer = Completer<List<Playlist>>();
    _playlistsCompleter = completer;

    return completer.future;
  }

  @override
  Future<void> addTrackToFavorites({required int trackId}) async {}

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) async {}

  @override
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePlaylist({required int playlistId}) async {}

  @override
  Future<Playlist> getPlaylist({required int playlistId}) async =>
      _playlists.singleWhere((playlist) => playlist.id == playlistId);

  @override
  Future<List<Track>> getPlaylistTracks({required int playlistId}) async =>
      _playlistTracksById[playlistId] ?? const [];

  @override
  Future<void> removeTrackFromFavorites({required int trackId}) async {}

  @override
  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  }) async {
    removedTrackIds.add(trackId);
    removedTrackPlaylistIds.add(playlistId);
  }

  @override
  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  }) async {}

  @override
  Future<Playlist> updatePlaylist({
    required int playlistId,
    required PlaylistUpsertInput input,
  }) async => throw UnimplementedError();

  @override
  Future<Playlist> uploadPlaylistCover({
    required int playlistId,
    required PlaylistCoverUploadInput input,
  }) async => throw UnimplementedError();
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

Playlist _playlist(int id, {required String name, int trackCount = 0}) {
  return Playlist(
    id: id,
    userId: 1,
    name: name,
    description: '',
    coverImagePath: '',
    visibility: PlaylistVisibility.private,
    trackCount: trackCount,
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
