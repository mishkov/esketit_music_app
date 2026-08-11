import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:esketit_music_app/use_case/downloads/downloads_storage.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';

class FakeDownloadsStorage implements DownloadsStorage {
  final StreamController<DownloadQueueSnapshot> _queueChanges =
      StreamController<DownloadQueueSnapshot>.broadcast();
  final StreamController<DownloadedLibrarySnapshot> _libraryChanges =
      StreamController<DownloadedLibrarySnapshot>.broadcast();

  DownloadQueueSnapshot queue = const DownloadQueueSnapshot.empty();
  DownloadedLibrarySnapshot library = const DownloadedLibrarySnapshot.empty();
  final Map<int, DownloadTrackSnapshot> trackSnapshots = {};
  final Map<int, List<Uri>> pendingArtworkUris = {};
  final List<DownloadTrackSnapshot> enqueuedTracks = [];
  final List<DownloadLyricsSnapshot> cachedLyrics = [];
  final List<({int jobId, int receivedBytes, int? totalBytes})>
  progressUpdates = [];
  final List<
    ({
      int jobId,
      String audioRelativePath,
      int audioByteCount,
      Map<Uri, String> artworkPaths,
    })
  >
  completedJobs = [];
  final List<({int jobId, DownloadFailureKind kind, String? message})>
  failedJobs = [];
  final List<int> removedTrackRequests = [];
  final List<String> acknowledgedDeletionPaths = [];
  List<String> pendingDeletionPaths = [];
  final Map<int, DownloadedTrackLocation> downloadedTrackLocations = {};
  DownloadRemovalResult? nextTrackRemovalResult;
  int _nextJobId = 1;

  Future<void> dispose() async {
    await _queueChanges.close();
    await _libraryChanges.close();
  }

  @override
  Stream<DownloadQueueSnapshot> watchQueue() => _queueChanges.stream;

  @override
  Stream<DownloadedLibrarySnapshot> watchLibrary() => _libraryChanges.stream;

  @override
  Future<DownloadQueueSnapshot> getQueue() async => queue;

  @override
  Future<DownloadedLibrarySnapshot> getLibrary() async => library;

  @override
  Future<void> enqueueTrack({
    required DownloadTrackSnapshot snapshot,
    DownloadReason? reason,
  }) async {
    enqueuedTracks.add(snapshot);
    trackSnapshots[snapshot.track.id] = snapshot;
    final job = _job(
      id: _nextJobId,
      track: snapshot.track,
      state: DownloadJobState.queued,
    );
    _nextJobId += 1;
    queue = DownloadQueueSnapshot(
      current: queue.current,
      queued: [...queue.queued, job],
      failures: queue.failures,
    );
    _queueChanges.add(queue);
  }

  @override
  Future<void> enqueueAlbum(DownloadAlbumSnapshot snapshot) async {
    for (final track in snapshot.tracks) {
      await enqueueTrack(
        snapshot: track,
        reason: DownloadReason.album(snapshot.album.id),
      );
    }
  }

  @override
  Future<void> enqueuePlaylist(DownloadPlaylistSnapshot snapshot) async {
    for (final track in snapshot.tracks) {
      await enqueueTrack(
        snapshot: track,
        reason: DownloadReason.playlist(snapshot.playlist.id),
      );
    }
  }

  @override
  Future<DownloadJobSnapshot?> claimNextJob({required DateTime now}) async {
    if (queue.current != null || queue.queued.isEmpty) {
      return null;
    }
    final source = queue.queued.first;
    final current = _copyJob(
      source,
      state: DownloadJobState.downloading,
      attemptCount: source.attemptCount + 1,
    );
    queue = DownloadQueueSnapshot(
      current: current,
      queued: queue.queued.skip(1).toList(growable: false),
      failures: queue.failures,
    );
    _queueChanges.add(queue);

    return current;
  }

  @override
  Future<DownloadTrackSnapshot?> getTrackSnapshot({
    required int trackId,
  }) async => trackSnapshots[trackId];

  @override
  Future<List<Uri>> getPendingArtworkUris({required int trackId}) async {
    return pendingArtworkUris[trackId] ?? const [];
  }

  @override
  Future<void> updateJobProgress({
    required int jobId,
    required int receivedBytes,
    required int? totalBytes,
    String? temporaryRelativePath,
    String? entityTag,
    String? lastModified,
  }) async {
    progressUpdates.add((
      jobId: jobId,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
    ));
    final current = queue.current;
    if (current != null && current.id == jobId) {
      queue = DownloadQueueSnapshot(
        current: _copyJob(
          current,
          state: current.state,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        ),
        queued: queue.queued,
        failures: queue.failures,
      );
      _queueChanges.add(queue);
    }
  }

  @override
  Future<void> completeJob({
    required int jobId,
    required String audioRelativePath,
    required int audioByteCount,
    Map<Uri, String> cachedArtworkRelativePaths = const {},
    String? entityTag,
    String? lastModified,
  }) async {
    completedJobs.add((
      jobId: jobId,
      audioRelativePath: audioRelativePath,
      audioByteCount: audioByteCount,
      artworkPaths: Map<Uri, String>.of(cachedArtworkRelativePaths),
    ));
    final trackId = queue.current?.trackId;
    queue = DownloadQueueSnapshot(
      current: null,
      queued: queue.queued,
      failures: queue.failures,
    );
    _queueChanges.add(queue);
    if (trackId != null) {
      pendingArtworkUris[trackId] = const [];
      final track = trackSnapshots[trackId]?.track;
      if (track != null) {
        library = DownloadedLibrarySnapshot(
          tracks: [
            ...library.tracks.where((item) => item.id != trackId),
            track,
          ],
          authors: library.authors,
          albums: library.albums,
          playlists: library.playlists,
        );
        _libraryChanges.add(library);
      }
    }
  }

  @override
  Future<DownloadRemovalResult> failJob({
    required int jobId,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  }) async {
    failedJobs.add((jobId: jobId, kind: failureKind, message: failureMessage));
    DownloadJobSnapshot? source;
    if (queue.current?.id == jobId) {
      source = queue.current;
    } else {
      source = queue.queued.where((job) => job.id == jobId).firstOrNull;
    }
    final failures = [...queue.failures];
    if (source != null) {
      failures.add(_copyJob(source, state: DownloadJobState.failed));
    }
    queue = DownloadQueueSnapshot(
      current: queue.current?.id == jobId ? null : queue.current,
      queued: queue.queued.where((job) => job.id != jobId).toList(),
      failures: failures,
    );
    _queueChanges.add(queue);

    return const DownloadRemovalResult.empty();
  }

  @override
  Future<void> cacheLyrics(DownloadLyricsSnapshot snapshot) async {
    cachedLyrics.add(snapshot);
    final current = trackSnapshots[snapshot.trackId];
    if (current != null) {
      trackSnapshots[snapshot.trackId] = DownloadTrackSnapshot(
        track: current.track,
        album: current.album,
        lyrics: snapshot,
      );
    }
  }

  @override
  Future<DownloadLyricsSnapshot?> getLyricsSnapshot({
    required int trackId,
  }) async => trackSnapshots[trackId]?.lyrics;

  @override
  Future<DownloadRemovalResult> removeTrack({required int trackId}) async {
    removedTrackRequests.add(trackId);
    queue = DownloadQueueSnapshot(
      current: queue.current?.trackId == trackId ? null : queue.current,
      queued: queue.queued.where((job) => job.trackId != trackId).toList(),
      failures: queue.failures.where((job) => job.trackId != trackId).toList(),
    );
    trackSnapshots.remove(trackId);
    library = DownloadedLibrarySnapshot(
      tracks: library.tracks.where((track) => track.id != trackId).toList(),
      authors: library.authors,
      albums: library.albums,
      playlists: library.playlists,
    );
    _queueChanges.add(queue);
    _libraryChanges.add(library);
    final configured = nextTrackRemovalResult;
    nextTrackRemovalResult = null;

    return configured ??
        DownloadRemovalResult(
          removedTrackIds: [trackId],
          relativePathsToDelete: const [],
        );
  }

  @override
  Future<void> acknowledgeDeletedPaths(Iterable<String> relativePaths) async {
    acknowledgedDeletionPaths.addAll(relativePaths);
    pendingDeletionPaths.removeWhere(relativePaths.toSet().contains);
  }

  @override
  Future<TrackLyrics?> getCachedLyrics({required int trackId}) async {
    return trackSnapshots[trackId]?.lyrics.lyrics;
  }

  @override
  Future<List<Track>> getDownloadedTracks() async => library.tracks;

  @override
  Future<Track?> getDownloadedTrack({required int trackId}) async {
    return library.tracks.where((track) => track.id == trackId).firstOrNull;
  }

  @override
  Future<List<Author>> getDownloadedAuthors() async => library.authors;

  @override
  Future<List<Album>> getDownloadedAlbums() async => library.albums;

  @override
  Future<List<Playlist>> getDownloadedPlaylists() async => library.playlists;

  @override
  Future<PlaylistDetailsSnapshot?> getDownloadedPlaylistDetails({
    required int playlistId,
  }) async => null;

  @override
  Future<List<Track>> getDownloadedTracksByAuthor({
    required int authorId,
  }) async => const [];

  @override
  Future<List<Track>> getDownloadedTracksByAlbum({
    required int albumId,
  }) async => const [];

  @override
  Future<DownloadedTrackLocation?> getDownloadedTrackLocation({
    required int trackId,
  }) async => downloadedTrackLocations[trackId];

  @override
  Stream<Set<int>> watchDownloadedTrackIds() {
    return _libraryChanges.stream.map(
      (snapshot) => snapshot.tracks.map((track) => track.id).toSet(),
    );
  }

  @override
  Future<void> acknowledgeFailures() async {
    queue = DownloadQueueSnapshot(
      current: queue.current,
      queued: queue.queued,
      failures: const [],
    );
    _queueChanges.add(queue);
  }

  @override
  Future<void> recoverInterruptedJobs() async {}

  @override
  Future<void> scheduleJobRetry({
    required int jobId,
    required DateTime nextAttemptAt,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  }) async {}

  @override
  Future<DownloadRemovalResult> removeAlbum({required int albumId}) async {
    return const DownloadRemovalResult.empty();
  }

  @override
  Future<DownloadRemovalResult> removePlaylist({
    required int playlistId,
  }) async => const DownloadRemovalResult.empty();

  @override
  Future<DownloadRemovalResult> removeAll() async {
    return const DownloadRemovalResult.empty();
  }

  @override
  Future<List<String>> getPendingDeletionPaths() async => pendingDeletionPaths;

  DownloadJobSnapshot _job({
    required int id,
    required Track track,
    required DownloadJobState state,
  }) {
    return DownloadJobSnapshot(
      id: id,
      batchId: 1,
      trackId: track.id,
      trackName: track.name,
      state: state,
      enqueuedAt: DateTime.utc(2026, 8, 10),
      attemptCount: 0,
      receivedBytes: 0,
      totalBytes: null,
      nextAttemptAt: null,
      temporaryRelativePath: null,
      entityTag: null,
      lastModified: null,
      failureKind: null,
      failureMessage: null,
    );
  }

  DownloadJobSnapshot _copyJob(
    DownloadJobSnapshot source, {
    required DownloadJobState state,
    int? attemptCount,
    int? receivedBytes,
    int? totalBytes,
  }) {
    return DownloadJobSnapshot(
      id: source.id,
      batchId: source.batchId,
      trackId: source.trackId,
      trackName: source.trackName,
      state: state,
      enqueuedAt: source.enqueuedAt,
      attemptCount: attemptCount ?? source.attemptCount,
      receivedBytes: receivedBytes ?? source.receivedBytes,
      totalBytes: totalBytes ?? source.totalBytes,
      nextAttemptAt: source.nextAttemptAt,
      temporaryRelativePath: source.temporaryRelativePath,
      entityTag: source.entityTag,
      lastModified: source.lastModified,
      failureKind: source.failureKind,
      failureMessage: source.failureMessage,
    );
  }
}

class FakeDownloadTransfer implements DownloadTransfer {
  final StreamController<DownloadTransferUpdate> _updates =
      StreamController<DownloadTransferUpdate>.broadcast();
  final Map<String, DownloadTransferRecord> records = {};
  final Set<String> existingFiles = {};
  final Map<String, int> fileSizes = {};
  final List<DownloadTransferTask> enqueuedTasks = [];
  final List<String> canceledTaskIds = [];
  final List<DownloadTransferDestination> removedFiles = [];
  int cancelAllCount = 0;
  int notificationPermissionRequestCount = 0;
  int rescheduleMissingTasksCount = 0;
  bool started = false;
  DownloadNotificationPermissionStatus notificationPermissionStatus =
      DownloadNotificationPermissionStatus.granted;
  DownloadTransferRecoveryResult recoveryResult =
      const DownloadTransferRecoveryResult(
        rescheduledTasks: [],
        failedToRescheduleTasks: [],
      );

  @override
  Stream<DownloadTransferUpdate> get updates => _updates.stream;

  Future<void> closeController() => _updates.close();

  @override
  Future<void> start(DownloadTransferNotificationMessages messages) async {
    started = true;
  }

  @override
  Future<bool> enqueue(DownloadTransferTask task) async {
    enqueuedTasks.add(task);
    records[task.id] = DownloadTransferRecord(
      task: task,
      status: DownloadTransferStatus.enqueued,
    );

    return true;
  }

  void setComplete(DownloadTransferTask task, {required int size}) {
    records[task.id] = DownloadTransferRecord(
      task: task,
      status: DownloadTransferStatus.complete,
      progress: 1,
      expectedFileSize: size,
    );
    existingFiles.add(_destinationKey(task.destination));
    fileSizes[_destinationKey(task.destination)] = size;
  }

  void emitStatus(
    DownloadTransferTask task,
    DownloadTransferStatus status, {
    DownloadTransferException? exception,
  }) {
    records[task.id] = DownloadTransferRecord(
      task: task,
      status: status,
      exception: exception,
    );
    _updates.add(
      DownloadTransferStatusUpdate(
        task: task,
        status: status,
        exception: exception,
      ),
    );
  }

  void emitProgress(
    DownloadTransferTask task, {
    required double progress,
    required int? expectedFileSize,
  }) {
    _updates.add(
      DownloadTransferProgressUpdate(
        task: task,
        progress: progress,
        expectedFileSize: expectedFileSize,
      ),
    );
  }

  @override
  Future<bool> cancel(String taskId) async {
    canceledTaskIds.add(taskId);
    final record = records[taskId];
    if (record != null) {
      records[taskId] = DownloadTransferRecord(
        task: record.task,
        status: DownloadTransferStatus.canceled,
      );
    }

    return true;
  }

  @override
  Future<bool> cancelAll() async {
    cancelAllCount += 1;

    return true;
  }

  @override
  Future<List<DownloadTransferRecord>> getRecords() async {
    return records.values.toList(growable: false);
  }

  @override
  Future<DownloadTransferRecord?> getRecord(String taskId) async {
    return records[taskId];
  }

  @override
  Future<void> deleteRecord(String taskId) async {
    records.remove(taskId);
  }

  @override
  Future<bool> fileExists(DownloadTransferDestination destination) async {
    return existingFiles.contains(_destinationKey(destination));
  }

  @override
  Future<int?> fileSize(DownloadTransferDestination destination) async {
    return fileSizes[_destinationKey(destination)];
  }

  @override
  Future<bool> removeFile(DownloadTransferDestination destination) async {
    removedFiles.add(destination);
    existingFiles.remove(_destinationKey(destination));
    fileSizes.remove(_destinationKey(destination));

    return true;
  }

  @override
  Future<DownloadTransferRecoveryResult> rescheduleMissingTasks() async {
    rescheduleMissingTasksCount += 1;

    return recoveryResult;
  }

  @override
  Future<DownloadNotificationPermissionStatus>
  getNotificationPermissionStatus() async {
    return notificationPermissionStatus;
  }

  @override
  Future<DownloadNotificationPermissionStatus>
  requestNotificationPermission() async {
    notificationPermissionRequestCount += 1;

    return notificationPermissionStatus;
  }

  @override
  Future<bool> shouldShowNotificationPermissionRationale() async => false;

  @override
  Future<bool> tasksFinished({String? ignoringTaskId}) async => false;

  @override
  Future<List<DownloadTransferTask>> getActiveTasks() async => const [];

  @override
  Future<String> resolveFilePath(
    DownloadTransferDestination destination,
  ) async => _destinationKey(destination);

  @override
  Future<void> dispose() async {}

  static String _destinationKey(DownloadTransferDestination destination) {
    if (destination.relativeDirectory.isEmpty) {
      return destination.filename;
    }

    return '${destination.relativeDirectory}/${destination.filename}';
  }
}

class FakeDownloadAlerts implements DownloadAlertNotifications {
  int initializeCount = 0;
  int downloadFailuresCount = 0;
  int insufficientStorageCount = 0;

  @override
  Future<void> initialize(DownloadAlertNotificationMessages messages) async {
    initializeCount += 1;
  }

  @override
  Future<void> showDownloadFailures() async {
    downloadFailuresCount += 1;
  }

  @override
  Future<void> showInsufficientStorage() async {
    insufficientStorageCount += 1;
  }

  @override
  Future<void> dispose() async {}
}

class FakeLyricsStorage implements LyricsStorage {
  TrackLyrics? result;
  Object? error;
  final List<int> requestedTrackIds = [];

  @override
  Future<TrackLyrics?> getTrackLyrics({required int trackId}) async {
    requestedTrackIds.add(trackId);
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }

    return result;
  }
}

class FakeCatalogStorage implements CatalogStorage {
  final Map<int, Album> albums = {};

  @override
  Future<Album?> getAlbum({required int albumId}) async => albums[albumId];

  @override
  Future<List<Track>> getAlbumTracks({required Album album}) async => const [];

  @override
  Future<List<Author>> getPublishedAuthors() async => const [];

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({
    required int authorId,
  }) async {
    return const [];
  }

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

class FakeErrorReporter implements ErrorReporter {
  final List<Breadcrumb> breadcrumbs = [];
  final List<AppError> errors = [];

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> reportError(AppError error) async {
    errors.add(error);
  }

  @override
  Future<void> setUserId(String? id) async {}
}
