import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/sqflite_downloads_storage.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  SqfliteDownloadsStorage? currentStorage;
  SqfliteDownloadsStorage getStorage() => currentStorage!;
  final now = DateTime.utc(2026, 8, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    currentStorage = await SqfliteDownloadsStorage.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfi,
      localPathResolver: (path) => '/application-support/downloads/$path',
      clock: () => now,
    );
  });

  tearDown(() => getStorage().close());

  test('round-trips completed track graph, artwork, and lyrics', () async {
    final storage = getStorage();
    final album = _album(trackIds: const [1]);
    final snapshot = _snapshot(
      track: _track(id: 1, albumId: album.id),
      album: album,
      lyrics: DownloadLyricsSnapshot.available(_lyrics(trackId: 1)),
    );

    await storage.enqueueTrack(snapshot: snapshot);

    final pendingSnapshot = await storage.getTrackSnapshot(trackId: 1);
    expect(pendingSnapshot?.track, snapshot.track);
    expect(pendingSnapshot?.album, album);
    expect(pendingSnapshot?.lyrics.lyrics, _lyrics(trackId: 1));
    final artworkUris = await storage.getPendingArtworkUris(trackId: 1);
    expect(
      artworkUris,
      containsAll([
        Uri.parse('https://music.test/images/track-1.jpg'),
        Uri.parse('https://music.test/images/author.jpg'),
        Uri.parse('https://music.test/images/album.jpg'),
      ]),
    );

    final job = await storage.claimNextJob(now: now);
    expect(job?.trackId, 1);
    await storage.updateJobProgress(
      jobId: job!.id,
      receivedBytes: 50,
      totalBytes: 100,
      temporaryRelativePath: 'partial/1.part',
    );
    await storage.completeJob(
      jobId: job.id,
      audioRelativePath: 'audio/1.mp3',
      audioByteCount: 100,
      cachedArtworkRelativePaths: {
        for (final uri in artworkUris) uri: 'artwork/${uri.pathSegments.last}',
      },
    );

    final downloadedTrack = await storage.getDownloadedTrack(trackId: 1);
    expect(downloadedTrack?.name, 'Track 1');
    expect(downloadedTrack?.createdAt, DateTime.utc(2026, 7, 1));
    expect(
      (downloadedTrack?.file as LocalFile).path,
      '/application-support/downloads/audio/1.mp3',
    );
    expect(
      (downloadedTrack?.image as LocalFile).path,
      '/application-support/downloads/artwork/track-1.jpg',
    );
    expect(await storage.getCachedLyrics(trackId: 1), _lyrics(trackId: 1));
    final downloadedAuthor = (await storage.getDownloadedAuthors()).single;
    expect(downloadedAuthor.currentName, 'Artist');
    expect(
      downloadedAuthor.primaryPhotoUrl,
      'file:///application-support/downloads/artwork/author.jpg',
    );
    expect((await storage.getDownloadedAlbums()).single.trackIds, [1]);
    expect((await storage.getLibrary()).albumDownloadIds, isEmpty);
    expect(
      await storage.getDownloadedTrackLocation(trackId: 1),
      const DownloadedTrackLocation(
        trackId: 1,
        audioRelativePath: 'audio/1.mp3',
        artworkRelativePath: 'artwork/track-1.jpg',
      ),
    );
    expect((await storage.getQueue()).hasWork, isFalse);
  });

  test(
    'strict FIFO retry blocks newer jobs until the head terminates',
    () async {
      final storage = getStorage();
      await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 1)));
      await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 2)));

      final firstAttempt = await storage.claimNextJob(now: now);
      expect(firstAttempt?.trackId, 1);
      await storage.updateJobProgress(
        jobId: firstAttempt!.id,
        receivedBytes: 20,
        totalBytes: 100,
        temporaryRelativePath: 'partial/1.part',
      );
      await storage.scheduleJobRetry(
        jobId: firstAttempt.id,
        nextAttemptAt: now.add(const Duration(minutes: 1)),
        failureKind: DownloadFailureKind.network,
      );

      expect(
        await storage.claimNextJob(now: now.add(const Duration(seconds: 30))),
        isNull,
      );
      final secondAttempt = await storage.claimNextJob(
        now: now.add(const Duration(minutes: 2)),
      );
      expect(secondAttempt?.id, firstAttempt.id);
      expect(secondAttempt?.attemptCount, 2);
      final cleanup = await storage.failJob(
        jobId: secondAttempt!.id,
        failureKind: DownloadFailureKind.network,
      );
      expect(cleanup.relativePathsToDelete, ['partial/1.part']);
      expect(await storage.getPendingDeletionPaths(), ['partial/1.part']);
      await storage.acknowledgeDeletedPaths(cleanup.relativePathsToDelete);
      expect(await storage.getPendingDeletionPaths(), isEmpty);

      final secondTrack = await storage.claimNextJob(
        now: now.add(const Duration(minutes: 2)),
      );
      expect(secondTrack?.trackId, 2);
      expect((await storage.getQueue()).failures.single.trackId, 1);
      await storage.acknowledgeFailures();
      expect((await storage.getQueue()).failures, isEmpty);
    },
  );

  test('recovers a job left downloading after worker termination', () async {
    final storage = getStorage();
    await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 1)));
    final interrupted = await storage.claimNextJob(now: now);
    expect(interrupted?.attemptCount, 1);

    await storage.recoverInterruptedJobs();

    final reclaimed = await storage.claimNextJob(
      now: now.add(const Duration(seconds: 1)),
    );
    expect(reclaimed?.id, interrupted?.id);
    expect(reclaimed?.attemptCount, 2);
  });

  test(
    'can fail the current and queued jobs when storage is exhausted',
    () async {
      final storage = getStorage();
      await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 1)));
      await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 2)));
      final current = await storage.claimNextJob(now: now);
      final queued = (await storage.getQueue()).queued.single;

      await storage.failJob(
        jobId: current!.id,
        failureKind: DownloadFailureKind.insufficientStorage,
      );
      await storage.failJob(
        jobId: queued.id,
        failureKind: DownloadFailureKind.insufficientStorage,
      );

      final queue = await storage.getQueue();
      expect(queue.hasWork, isFalse);
      expect(queue.failures.map((job) => job.trackId), [1, 2]);
    },
  );

  test('collection removal preserves files owned by another reason', () async {
    final storage = getStorage();
    final album = _album(trackIds: const [1]);
    final snapshot = _snapshot(
      track: _track(id: 1, albumId: album.id),
      album: album,
    );
    await storage.enqueueTrack(snapshot: snapshot);
    await storage.enqueueAlbum(
      DownloadAlbumSnapshot(album: album, tracks: [snapshot]),
    );
    final job = await storage.claimNextJob(now: now);
    await storage.completeJob(
      jobId: job!.id,
      audioRelativePath: 'audio/1.mp3',
      audioByteCount: 100,
    );
    expect((await storage.getLibrary()).albumDownloadIds, {album.id});

    final albumRemoval = await storage.removeAlbum(albumId: album.id);
    expect(albumRemoval, const DownloadRemovalResult.empty());
    expect((await storage.getLibrary()).albumDownloadIds, isEmpty);
    expect(await storage.getDownloadedTrack(trackId: 1), isNotNull);

    final trackRemoval = await storage.removeTrack(trackId: 1);
    expect(trackRemoval.removedTrackIds, [1]);
    expect(trackRemoval.removedDownloadedTrackIds, [1]);
    expect(trackRemoval.relativePathsToDelete, ['audio/1.mp3']);
    expect(await storage.getDownloadedTrack(trackId: 1), isNull);
  });

  test(
    'playlist snapshot keeps order and removes only playlist reasons',
    () async {
      final storage = getStorage();
      final first = _snapshot(track: _track(id: 1));
      final second = _snapshot(track: _track(id: 2));
      final playlist = _playlist(trackCount: 2);
      await storage.enqueuePlaylist(
        DownloadPlaylistSnapshot(playlist: playlist, tracks: [second, first]),
      );
      for (var index = 0; index < 2; index += 1) {
        final job = await storage.claimNextJob(now: now);
        await storage.completeJob(
          jobId: job!.id,
          audioRelativePath: 'audio/${job.trackId}.mp3',
          audioByteCount: 100,
        );
      }

      final details = await storage.getDownloadedPlaylistDetails(
        playlistId: playlist.id,
      );
      expect(details?.tracks.map((track) => track.id), [2, 1]);
      expect((await storage.getDownloadedPlaylists()).single.name, 'Playlist');
      expect((await storage.getLibrary()).playlistDownloadIds, {playlist.id});

      final removal = await storage.removePlaylist(playlistId: playlist.id);
      expect(removal.removedTrackIds, [1, 2]);
      expect(removal.removedDownloadedTrackIds, [1, 2]);
      expect(removal.relativePathsToDelete, ['audio/1.mp3', 'audio/2.mp3']);
      expect(await storage.getDownloadedPlaylists(), isEmpty);
    },
  );

  test('playlist re-download keeps its original frozen membership', () async {
    final storage = getStorage();
    final playlist = _playlist(trackCount: 1);
    final originalTrack = _snapshot(track: _track(id: 1));
    await storage.enqueuePlaylist(
      DownloadPlaylistSnapshot(playlist: playlist, tracks: [originalTrack]),
    );
    final originalJob = await storage.claimNextJob(now: now);
    await storage.failJob(
      jobId: originalJob!.id,
      failureKind: DownloadFailureKind.network,
    );

    await storage.enqueuePlaylist(
      DownloadPlaylistSnapshot(
        playlist: playlist,
        tracks: [_snapshot(track: _track(id: 2))],
      ),
    );

    expect(await storage.getTrackSnapshot(trackId: 2), isNull);
    final queue = await storage.getQueue();
    expect(queue.queued.single.trackId, 1);
    expect(queue.failures, isEmpty);
  });

  test(
    'not-fetched lyrics can be replaced without implying a cached 404',
    () async {
      final storage = getStorage();
      await storage.enqueueTrack(snapshot: _snapshot(track: _track(id: 1)));
      expect(
        (await storage.getLyricsSnapshot(trackId: 1))?.availability,
        DownloadLyricsAvailability.notFetched,
      );

      await storage.cacheLyrics(const DownloadLyricsSnapshot.notAvailable(1));
      expect(
        (await storage.getLyricsSnapshot(trackId: 1))?.availability,
        DownloadLyricsAvailability.notAvailable,
      );
      expect(await storage.getCachedLyrics(trackId: 1), isNull);
    },
  );
}

DownloadTrackSnapshot _snapshot({
  required Track track,
  Album? album,
  DownloadLyricsSnapshot? lyrics,
}) {
  return DownloadTrackSnapshot(
    track: track,
    album: album,
    lyrics: lyrics ?? DownloadLyricsSnapshot.notFetched(track.id),
  );
}

Track _track({required int id, int? albumId}) {
  return Track(
    id: id,
    albumId: albumId,
    name: 'Track $id',
    authors: const [
      Author(
        id: 7,
        currentName: 'Artist',
        photos: ['https://music.test/images/author.jpg'],
      ),
    ],
    addionalInfo: [TextTrackInfo(title: 'History', text: 'Track story')],
    file: HttpFile(uri: Uri.parse('https://music.test/audio/$id.mp3')),
    image: HttpFile(uri: Uri.parse('https://music.test/images/track-$id.jpg')),
    isFavorite: true,
    isDisliked: false,
    isAvailable: true,
    createdAt: DateTime.utc(2026, 7, 1),
  );
}

Album _album({required List<int> trackIds}) {
  return Album(
    id: 10,
    title: 'Album',
    coverImage: HttpFile(uri: Uri.parse('https://music.test/images/album.jpg')),
    authorIds: const [7],
    releaseDate: DateTime.utc(2026, 6, 1),
    isPublished: true,
    trackIds: trackIds,
    additionalInfo: [TextTrackInfo(title: 'Album info', text: 'Story')],
  );
}

Playlist _playlist({required int trackCount}) {
  return Playlist(
    id: 20,
    userId: 3,
    name: 'Playlist',
    description: 'Frozen snapshot',
    coverImagePath: 'https://music.test/images/playlist.jpg',
    visibility: PlaylistVisibility.private,
    trackCount: trackCount,
    system: false,
    kind: PlaylistKind.custom,
  );
}

TrackLyrics _lyrics({required int trackId}) {
  return TrackLyrics(
    trackId: trackId,
    type: TrackLyricsType.synced,
    languageCode: 'en',
    isVerified: true,
    source: 'artist',
    plainText: null,
    lines: const [
      SyncedTrackLyricsLine(startMs: 0, endMs: 1000, text: 'Line one'),
    ],
  );
}
