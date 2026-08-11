import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/downloads/download_source_resolver.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'downloads_test_fakes.dart';

void main() {
  group('DownloadsBloc', () {
    test('startup skips native recovery when the queue has no work', () async {
      final harness = await _DownloadsBlocHarness.start();
      addTearDown(harness.close);

      expect(harness.transfer.rescheduleMissingTasksCount, 0);
      expect(harness.bloc.state.isReady, isTrue);
    });

    test('enqueues a not-fetched snapshot and native audio task', () async {
      final harness = await _DownloadsBlocHarness.start();
      addTearDown(harness.close);
      final track = _track(1);

      harness.bloc.add(DownloadTrackRequested(track: track));

      await _waitUntil(() => harness.storage.enqueuedTracks.length == 1);
      await _waitUntil(() => harness.transfer.enqueuedTasks.isNotEmpty);
      final snapshot = harness.storage.enqueuedTracks.single;
      final task = harness.transfer.enqueuedTasks.singleWhere(
        (item) => item.purpose == DownloadTransferPurpose.audio,
      );
      expect(snapshot.track, track);
      expect(
        snapshot.lyrics.availability,
        DownloadLyricsAvailability.notFetched,
      );
      expect(snapshot.lyrics.lyrics, isNull);
      expect(task.id, 'offline-audio-1');
      expect(task.remoteUri, (track.file as HttpFile).uri);
      expect(task.correlationId, '1');
      expect(task.destination.relativeDirectory, 'downloads/audio');
      expect(task.destination.filename, '1.mp3');
      expect(task.metadata['trackId'], '1');
    });

    test(
      'requests notification permission when its status is denied',
      () async {
        final transfer = FakeDownloadTransfer()
          ..notificationPermissionStatus =
              DownloadNotificationPermissionStatus.denied;
        final harness = await _DownloadsBlocHarness.start(transfer: transfer);
        addTearDown(harness.close);

        harness.bloc.add(DownloadTrackRequested(track: _track(1)));
        await _waitUntil(
          () => transfer.notificationPermissionRequestCount == 1,
        );
        harness.bloc.add(DownloadTrackRequested(track: _track(2)));
        await _waitUntil(() => harness.storage.enqueuedTracks.length == 2);

        expect(transfer.notificationPermissionRequestCount, 1);
      },
    );

    for (final (:status, :failureKind) in [
      (
        status: DownloadTransferStatus.failed,
        failureKind: DownloadFailureKind.network,
      ),
      (
        status: DownloadTransferStatus.notFound,
        failureKind: DownloadFailureKind.server,
      ),
    ]) {
      test(
        'startup marks an exhausted ${status.name} transfer failed',
        () async {
          final track = _track(1);
          final storage = FakeDownloadsStorage();
          await storage.enqueueTrack(snapshot: _snapshot(track));
          await storage.claimNextJob(now: DateTime.utc(2026, 8, 10));
          final transfer = FakeDownloadTransfer();
          final task = _audioTransferTask(track);
          transfer.records[task.id] = DownloadTransferRecord(
            task: task,
            status: status,
            exception: status == DownloadTransferStatus.failed
                ? const DownloadTransferException(
                    kind: DownloadTransferExceptionKind.connection,
                    description: 'Retries exhausted',
                  )
                : null,
          );

          final harness = await _DownloadsBlocHarness.start(
            storage: storage,
            transfer: transfer,
          );
          addTearDown(harness.close);

          expect(storage.failedJobs, hasLength(1));
          expect(transfer.rescheduleMissingTasksCount, 1);
          expect(storage.failedJobs.single.kind, failureKind);
          expect(transfer.enqueuedTasks, isEmpty);
          expect(
            harness.bloc.state.statusForTrack(track.id),
            TrackDownloadState.failed,
          );
          expect(harness.alerts.downloadFailuresCount, 0);
        },
      );
    }

    test('startup fails a native task that could not be restored', () async {
      final track = _track(1);
      final storage = FakeDownloadsStorage();
      await storage.enqueueTrack(snapshot: _snapshot(track));
      await storage.claimNextJob(now: DateTime.utc(2026, 8, 10));
      final transfer = FakeDownloadTransfer()
        ..recoveryResult = DownloadTransferRecoveryResult(
          rescheduledTasks: const [],
          failedToRescheduleTasks: [_audioTransferTask(track)],
        );

      final harness = await _DownloadsBlocHarness.start(
        storage: storage,
        transfer: transfer,
      );
      addTearDown(harness.close);

      expect(storage.failedJobs, hasLength(1));
      expect(storage.failedJobs.single.kind, DownloadFailureKind.unknown);
      expect(transfer.enqueuedTasks, isEmpty);
      expect(harness.alerts.downloadFailuresCount, 1);
    });

    test('startup cancels and removes an orphaned audio transfer', () async {
      final track = _track(1);
      final transfer = FakeDownloadTransfer();
      final task = _audioTransferTask(track);
      transfer.records[task.id] = DownloadTransferRecord(
        task: task,
        status: DownloadTransferStatus.running,
      );

      final harness = await _DownloadsBlocHarness.start(transfer: transfer);
      addTearDown(harness.close);

      expect(transfer.canceledTaskIds, [task.id]);
      expect(transfer.records, isEmpty);
      expect(transfer.removedFiles, [task.destination]);
    });

    test('startup retries file deletions persisted by storage', () async {
      final storage = FakeDownloadsStorage()
        ..pendingDeletionPaths = ['downloads/audio/old.mp3'];

      final harness = await _DownloadsBlocHarness.start(storage: storage);
      addTearDown(harness.close);

      expect(harness.transfer.removedFiles, hasLength(1));
      expect(
        harness.transfer.removedFiles.single.relativeDirectory,
        'downloads/audio',
      );
      expect(harness.transfer.removedFiles.single.filename, 'old.mp3');
      expect(storage.pendingDeletionPaths, isEmpty);
      expect(storage.acknowledgedDeletionPaths, ['downloads/audio/old.mp3']);
    });

    test(
      'application failures produce one alert after remaining work completes',
      () async {
        final storage = FakeDownloadsStorage();
        final invalidTrack = _track(1).copyWith(file: HttpFile(uri: Uri()));
        final validTrack = _track(2);
        await storage.enqueueTrack(snapshot: _snapshot(invalidTrack));
        await storage.enqueueTrack(snapshot: _snapshot(validTrack));

        final harness = await _DownloadsBlocHarness.start(storage: storage);
        addTearDown(harness.close);
        await _waitUntil(() => storage.failedJobs.length == 1);
        await _waitUntil(() => harness.transfer.enqueuedTasks.isNotEmpty);
        expect(harness.alerts.downloadFailuresCount, 0);

        final audioTask = harness.transfer.enqueuedTasks.singleWhere(
          (task) => task.purpose == DownloadTransferPurpose.audio,
        );
        harness.transfer.setComplete(audioTask, size: 100);
        harness.transfer.emitStatus(audioTask, DownloadTransferStatus.complete);

        await _waitUntil(() => storage.completedJobs.length == 1);
        await _waitUntil(() => harness.alerts.downloadFailuresCount == 1);
        expect(harness.alerts.downloadFailuresCount, 1);
      },
    );

    test(
      'enqueues shared album artwork only once per synchronization',
      () async {
        final harness = await _DownloadsBlocHarness.start();
        addTearDown(harness.close);
        final firstTrack = _track(1);
        final secondTrack = _track(2);
        final sharedArtworkUri = Uri.parse(
          'https://example.test/images/shared.jpg',
        );
        harness.storage.pendingArtworkUris[firstTrack.id] = [sharedArtworkUri];
        harness.storage.pendingArtworkUris[secondTrack.id] = [sharedArtworkUri];

        harness.bloc.add(
          DownloadAlbumRequested(
            album: _album(firstTrack, secondTrack),
            tracks: [firstTrack, secondTrack],
          ),
        );

        await _waitUntil(
          () =>
              harness.transfer.enqueuedTasks
                  .where(
                    (task) => task.purpose == DownloadTransferPurpose.audio,
                  )
                  .length ==
              2,
        );
        await _waitUntil(
          () => harness.transfer.enqueuedTasks.any(
            (task) => task.purpose == DownloadTransferPurpose.artwork,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final artworkTasks = harness.transfer.enqueuedTasks.where(
          (task) => task.purpose == DownloadTransferPurpose.artwork,
        );
        expect(artworkTasks, hasLength(1));
      },
    );

    test('persists progress then completes with lyrics and artwork', () async {
      final lyrics = _lyrics(1);
      final harness = await _DownloadsBlocHarness.start(lyrics: lyrics);
      addTearDown(harness.close);
      final track = _track(1);
      final artworkUri = (track.image as HttpFile).uri;
      harness.storage.pendingArtworkUris[track.id] = [artworkUri];

      harness.bloc.add(DownloadTrackRequested(track: track));

      await _waitUntil(() => harness.transfer.enqueuedTasks.length == 2);
      final audioTask = harness.transfer.enqueuedTasks.singleWhere(
        (item) => item.purpose == DownloadTransferPurpose.audio,
      );
      final artworkTask = harness.transfer.enqueuedTasks.singleWhere(
        (item) => item.purpose == DownloadTransferPurpose.artwork,
      );
      harness.transfer.emitProgress(
        audioTask,
        progress: 0.4,
        expectedFileSize: 100,
      );
      await _waitUntil(() => harness.storage.progressUpdates.isNotEmpty);
      expect(harness.storage.progressUpdates.single, (
        jobId: 1,
        receivedBytes: 40,
        totalBytes: 100,
      ));

      harness.transfer.setComplete(audioTask, size: 100);
      harness.transfer.setComplete(artworkTask, size: 20);
      harness.transfer.emitStatus(audioTask, DownloadTransferStatus.complete);

      await _waitUntil(() => harness.storage.completedJobs.isNotEmpty);
      await _waitUntil(
        () =>
            harness.bloc.state.statusForTrack(track.id) ==
            TrackDownloadState.downloaded,
      );
      expect(harness.lyricsStorage.requestedTrackIds, [track.id]);
      expect(harness.storage.cachedLyrics, [
        DownloadLyricsSnapshot.available(lyrics),
      ]);
      final completion = harness.storage.completedJobs.single;
      expect(completion.jobId, 1);
      expect(completion.audioRelativePath, 'downloads/audio/1.mp3');
      expect(completion.audioByteCount, 100);
      expect(
        completion.artworkPaths[artworkUri],
        startsWith('downloads/artwork/'),
      );
    });

    test('native cancel removes the corresponding download request', () async {
      final harness = await _DownloadsBlocHarness.start();
      addTearDown(harness.close);
      final track = _track(1);
      harness.bloc.add(DownloadTrackRequested(track: track));
      await _waitUntil(() => harness.transfer.enqueuedTasks.isNotEmpty);
      final audioTask = harness.transfer.enqueuedTasks.singleWhere(
        (item) => item.purpose == DownloadTransferPurpose.audio,
      );

      harness.transfer.emitStatus(audioTask, DownloadTransferStatus.canceled);

      await _waitUntil(
        () => harness.storage.removedTrackRequests.contains(track.id),
      );
      expect(harness.storage.removedTrackRequests, [track.id]);
    });

    test('file-system failure stops and fails the whole queue once', () async {
      final harness = await _DownloadsBlocHarness.start();
      addTearDown(harness.close);
      harness.bloc.add(DownloadTrackRequested(track: _track(1)));
      harness.bloc.add(DownloadTrackRequested(track: _track(2)));

      await _waitUntil(
        () =>
            harness.storage.queue.current != null &&
            harness.storage.queue.queued.length == 1,
      );
      await _waitUntil(
        () =>
            harness.transfer.enqueuedTasks
                .where((task) => task.purpose == DownloadTransferPurpose.audio)
                .length ==
            2,
      );
      final firstAudioTask = harness.transfer.enqueuedTasks.firstWhere(
        (task) => task.purpose == DownloadTransferPurpose.audio,
      );
      harness.transfer.emitStatus(
        firstAudioTask,
        DownloadTransferStatus.failed,
        exception: const DownloadTransferException(
          kind: DownloadTransferExceptionKind.fileSystem,
          description: 'No space left',
        ),
      );

      await _waitUntil(() => harness.storage.failedJobs.length == 2);
      await _waitUntil(() => harness.alerts.insufficientStorageCount == 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(harness.transfer.cancelAllCount, 1);
      expect(
        harness.storage.failedJobs.map((failure) => failure.jobId).toSet(),
        {1, 2},
      );
      expect(
        harness.storage.failedJobs.map((failure) => failure.kind).toSet(),
        {DownloadFailureKind.insufficientStorage},
      );
      expect(harness.alerts.insufficientStorageCount, 1);
      expect(harness.alerts.downloadFailuresCount, 0);
    });

    test(
      'remove publishes removed track IDs and deletes returned paths',
      () async {
        final transfer = FakeDownloadTransfer();
        var playbackWasPrepared = false;
        final harness = await _DownloadsBlocHarness.start(
          transfer: transfer,
          preparePlaybackForTrackRemoval: (trackIds) async {
            expect(transfer.removedFiles, isEmpty);
            expect(trackIds, [1, 2]);
            playbackWasPrepared = true;
          },
        );
        addTearDown(harness.close);
        harness.storage.nextTrackRemovalResult = const DownloadRemovalResult(
          removedTrackIds: [1, 2],
          relativePathsToDelete: ['downloads/audio/1.mp3'],
        );

        harness.bloc.add(const RemoveTrackDownloadRequested(1));

        await _waitUntil(() => harness.bloc.state.removalSerial == 1);
        await _waitUntil(
          () => harness.storage.acknowledgedDeletionPaths.isNotEmpty,
        );
        expect(harness.bloc.state.lastRemovedTrackIds, [1, 2]);
        expect(playbackWasPrepared, isTrue);
        expect(harness.transfer.removedFiles, hasLength(1));
        expect(
          harness.transfer.removedFiles.single.relativeDirectory,
          'downloads/audio',
        );
        expect(harness.transfer.removedFiles.single.filename, '1.mp3');
        expect(harness.storage.acknowledgedDeletionPaths, [
          'downloads/audio/1.mp3',
        ]);
      },
    );
  });
}

class _DownloadsBlocHarness {
  _DownloadsBlocHarness._({
    required this.storage,
    required this.transfer,
    required this.alerts,
    required this.lyricsStorage,
    required this.bloc,
  });

  final FakeDownloadsStorage storage;
  final FakeDownloadTransfer transfer;
  final FakeDownloadAlerts alerts;
  final FakeLyricsStorage lyricsStorage;
  final DownloadsBloc bloc;

  static Future<_DownloadsBlocHarness> start({
    TrackLyrics? lyrics,
    FakeDownloadsStorage? storage,
    FakeDownloadTransfer? transfer,
    Future<void> Function(Iterable<int> trackIds)?
    preparePlaybackForTrackRemoval,
  }) async {
    final effectiveStorage = storage ?? FakeDownloadsStorage();
    final effectiveTransfer = transfer ?? FakeDownloadTransfer();
    final alerts = FakeDownloadAlerts();
    final lyricsStorage = FakeLyricsStorage()..result = lyrics;
    final bloc = DownloadsBloc(
      storage: effectiveStorage,
      transfer: effectiveTransfer,
      alertNotifications: alerts,
      sourceResolver: const _TestDownloadSourceResolver(),
      lyricsStorage: lyricsStorage,
      catalogStorage: FakeCatalogStorage(),
      errorReporter: FakeErrorReporter(),
      transferMessages: const DownloadTransferNotificationMessages(
        runningTitle: 'Downloading',
        runningBody: 'Downloading track',
        failedTitle: 'Download failed',
        failedBody: 'Some tracks failed',
        cancelActionLabel: 'Cancel',
      ),
      alertMessages: const DownloadAlertNotificationMessages(
        channelName: 'Downloads',
        channelDescription: 'Download alerts',
        failedTitle: 'Downloads finished',
        failedBody: 'Failed to download some tracks',
        lowStorageTitle: 'Low storage',
        lowStorageBody: 'Free some storage and try again',
      ),
      preparePlaybackForTrackRemoval: preparePlaybackForTrackRemoval,
    );
    final harness = _DownloadsBlocHarness._(
      storage: effectiveStorage,
      transfer: effectiveTransfer,
      alerts: alerts,
      lyricsStorage: lyricsStorage,
      bloc: bloc,
    );
    bloc.add(const DownloadsStarted());
    await _waitUntil(() => bloc.state.isReady);

    return harness;
  }

  Future<void> close() async {
    await bloc.close();
    await storage.dispose();
    await transfer.closeController();
  }
}

class _TestDownloadSourceResolver implements DownloadSourceResolver {
  const _TestDownloadSourceResolver();

  @override
  Uri? resolveRemoteUri(file) {
    return file is HttpFile && file.uri.toString().isNotEmpty ? file.uri : null;
  }
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 10, currentName: 'Author', photos: [])],
    addionalInfo: const [],
    file: HttpFile(uri: Uri.parse('https://example.test/audio/$id.mp3')),
    image: HttpFile(uri: Uri.parse('https://example.test/images/$id.jpg')),
    isFavorite: false,
    isDisliked: false,
    isAvailable: true,
  );
}

DownloadTrackSnapshot _snapshot(Track track) {
  return DownloadTrackSnapshot(
    track: track,
    lyrics: DownloadLyricsSnapshot.notFetched(track.id),
  );
}

DownloadTransferTask _audioTransferTask(Track track) {
  return DownloadTransferTask(
    id: 'offline-audio-1',
    purpose: DownloadTransferPurpose.audio,
    correlationId: '1',
    remoteUri: (track.file as HttpFile).uri,
    destination: DownloadTransferDestination(
      relativeDirectory: 'downloads/audio',
      filename: '${track.id}.mp3',
    ),
    displayName: track.name,
    creationTime: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
    metadata: {'jobId': '1', 'trackId': '${track.id}'},
  );
}

Album _album(Track firstTrack, Track secondTrack) {
  return Album(
    id: 1,
    title: 'Album',
    coverImage: HttpFile(
      uri: Uri.parse('https://example.test/images/shared.jpg'),
    ),
    authorIds: const [10],
    releaseDate: null,
    isPublished: true,
    trackIds: [firstTrack.id, secondTrack.id],
    additionalInfo: const [],
  );
}

TrackLyrics _lyrics(int trackId) {
  return TrackLyrics(
    trackId: trackId,
    type: TrackLyricsType.plain,
    languageCode: 'en',
    isVerified: true,
    source: 'test',
    plainText: 'Lyrics for track $trackId',
    lines: const [],
  );
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
