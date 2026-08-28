import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_album_details_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_playlist_details_screen.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/player/playback_repeat_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('downloaded album removes its explicit download reference', (
    tester,
  ) async {
    final album = _album();
    final downloadsBloc = _RecordingDownloadsBloc(
      _downloadsState(
        library: DownloadedLibrarySnapshot(
          tracks: const [],
          authors: const [],
          albums: [album],
          playlists: const [],
          albumDownloadIds: {album.id},
        ),
      ),
    );
    final playerBloc = _playerBloc();
    addTearDown(downloadsBloc.close);
    addTearDown(playerBloc.close);

    await _pumpScreen(
      tester,
      downloadsBloc: downloadsBloc,
      playerBloc: playerBloc,
      screen: DownloadedAlbumDetailsScreen(albumId: album.id),
    );
    await tester.ensureVisible(find.text('Remove download'));
    await tester.tap(find.text('Remove download'));

    expect(
      downloadsBloc.addedEvents,
      contains(RemoveAlbumDownloadRequested(album.id)),
    );
  });

  testWidgets('downloaded album hides removal without an album reference', (
    tester,
  ) async {
    final album = _album();
    final downloadsBloc = _RecordingDownloadsBloc(
      _downloadsState(
        library: DownloadedLibrarySnapshot(
          tracks: const [],
          authors: const [],
          albums: [album],
          playlists: const [],
        ),
      ),
    );
    final playerBloc = _playerBloc();
    addTearDown(downloadsBloc.close);
    addTearDown(playerBloc.close);

    await _pumpScreen(
      tester,
      downloadsBloc: downloadsBloc,
      playerBloc: playerBloc,
      screen: DownloadedAlbumDetailsScreen(albumId: album.id),
    );

    expect(find.text('Remove download'), findsNothing);
  });

  testWidgets('downloaded playlist removes its explicit download reference', (
    tester,
  ) async {
    const playlist = _playlist;
    final downloadsBloc = _RecordingDownloadsBloc(
      _downloadsState(
        library: const DownloadedLibrarySnapshot(
          tracks: [],
          authors: [],
          albums: [],
          playlists: [playlist],
          playlistDownloadIds: {7},
        ),
        downloadedPlaylistTracks: const {7: []},
      ),
    );
    final playerBloc = _playerBloc();
    addTearDown(downloadsBloc.close);
    addTearDown(playerBloc.close);

    await _pumpScreen(
      tester,
      downloadsBloc: downloadsBloc,
      playerBloc: playerBloc,
      screen: const DownloadedPlaylistDetailsScreen(playlistId: 7),
    );
    await tester.tap(find.text('Remove download'));

    expect(
      downloadsBloc.addedEvents,
      contains(const RemovePlaylistDownloadRequested(7)),
    );
  });

  testWidgets(
    'downloaded playlist hides removal without a playlist reference',
    (tester) async {
      const playlist = _playlist;
      final downloadsBloc = _RecordingDownloadsBloc(
        _downloadsState(
          library: const DownloadedLibrarySnapshot(
            tracks: [],
            authors: [],
            albums: [],
            playlists: [playlist],
          ),
          downloadedPlaylistTracks: const {7: []},
        ),
      );
      final playerBloc = _playerBloc();
      addTearDown(downloadsBloc.close);
      addTearDown(playerBloc.close);

      await _pumpScreen(
        tester,
        downloadsBloc: downloadsBloc,
        playerBloc: playerBloc,
        screen: const DownloadedPlaylistDetailsScreen(playlistId: 7),
      );

      expect(find.text('Remove download'), findsNothing);
    },
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required DownloadsBloc downloadsBloc,
  required PlayerBloc playerBloc,
  required Widget screen,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<DownloadsBloc>.value(value: downloadsBloc),
        BlocProvider<PlayerBloc>.value(value: playerBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

DownloadsState _downloadsState({
  required DownloadedLibrarySnapshot library,
  Map<int, List<Track>> downloadedPlaylistTracks = const {},
}) {
  return DownloadsState(
    availability: DownloadsAvailability.ready,
    queue: const DownloadQueueSnapshot.empty(),
    library: library,
    removalSerial: 0,
    lastRemovedTrackIds: const [],
    operationErrorSerial: 0,
    downloadedPlaylistTracks: downloadedPlaylistTracks,
    loadingDownloadedPlaylistIds: const {},
  );
}

PlayerBloc _playerBloc() {
  return PlayerBloc(
    initialState: const PlayerState(selectedTrack: null, isPlaying: false),
    player: const _FakeAudioPlayer(),
    autoplayStorage: const _FakeAutoplayStorage(),
    errorReporter: const _FakeErrorReporter(),
  );
}

Album _album() {
  return Album(
    id: 5,
    title: 'Offline album',
    coverImage: HttpFile(uri: Uri()),
    authorIds: const [],
    releaseDate: null,
    isPublished: true,
    trackIds: const [],
    additionalInfo: const [],
  );
}

const _playlist = Playlist(
  id: 7,
  userId: 1,
  name: 'Offline playlist',
  description: '',
  coverImagePath: '',
  visibility: PlaylistVisibility.private,
  trackCount: 0,
  system: false,
  kind: PlaylistKind.custom,
);

class _RecordingDownloadsBloc extends DownloadsBloc {
  _RecordingDownloadsBloc(this.testState) : super.unsupported();

  final DownloadsState testState;
  final List<DownloadsEvent> addedEvents = [];

  @override
  DownloadsState get state => testState;

  @override
  void add(DownloadsEvent event) {
    addedEvents.add(event);
  }
}

class _FakeAudioPlayer implements AudioPlayer {
  const _FakeAudioPlayer();

  @override
  Duration get currentPosition => Duration.zero;

  @override
  int? get currentIndex => null;

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
  Future<void> removeUpcomingTracks(Set<int> trackIds) async {}

  @override
  Future<void> removeTracks(Set<int> trackIds) async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode repeatMode) async {}

  @override
  Future<void> skipToNextTrack() async {}

  @override
  Future<void> skipToPreviousTrack() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> togglePlay() async {}
}

class _FakeAutoplayStorage implements AutoplayStorage {
  const _FakeAutoplayStorage();

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
  const _FakeErrorReporter();

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}
