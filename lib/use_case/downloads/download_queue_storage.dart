import 'package:esketit_music_app/use_case/downloads/download_models.dart';

abstract class DownloadQueueStorage {
  Stream<DownloadQueueSnapshot> watchQueue();

  Future<DownloadQueueSnapshot> getQueue();

  /// Returns the durable metadata needed to resume a job after process death.
  Future<DownloadTrackSnapshot?> getTrackSnapshot({required int trackId});

  /// Returns artwork that still needs to be cached for this track bundle.
  Future<List<Uri>> getPendingArtworkUris({required int trackId});

  /// Claims only the oldest active job. A delayed retry blocks newer jobs.
  Future<DownloadJobSnapshot?> claimNextJob({required DateTime now});

  /// Makes jobs left active by a terminated worker claimable again.
  Future<void> recoverInterruptedJobs();

  Future<void> updateJobProgress({
    required int jobId,
    required int receivedBytes,
    required int? totalBytes,
    String? temporaryRelativePath,
    String? entityTag,
    String? lastModified,
  });

  Future<void> scheduleJobRetry({
    required int jobId,
    required DateTime nextAttemptAt,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  });

  Future<void> completeJob({
    required int jobId,
    required String audioRelativePath,
    required int audioByteCount,
    Map<Uri, String> cachedArtworkRelativePaths = const {},
    String? entityTag,
    String? lastModified,
  });

  Future<DownloadRemovalResult> failJob({
    required int jobId,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  });

  Future<void> acknowledgeFailures();
}
