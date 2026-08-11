enum DownloadTransferStatus {
  enqueued,
  running,
  complete,
  notFound,
  failed,
  canceled,
  waitingToRetry,
  paused;

  bool get isFinal => switch (this) {
    complete || notFound || failed || canceled => true,
    enqueued || running || waitingToRetry || paused => false,
  };
}

enum DownloadTransferExceptionKind {
  general,
  fileSystem,
  invalidUrl,
  connection,
  resume,
  httpResponse,
}

class DownloadTransferException implements Exception {
  const DownloadTransferException({
    required this.kind,
    required this.description,
    this.httpResponseStatusCode,
  });

  final DownloadTransferExceptionKind kind;
  final String description;
  final int? httpResponseStatusCode;

  @override
  String toString() => 'DownloadTransferException($kind): $description';
}

enum DownloadNotificationPermissionStatus {
  undetermined,
  denied,
  granted,
  partial,
  requestError,
}

enum DownloadTransferPurpose { audio, artwork }

class DownloadTransferDestination {
  const DownloadTransferDestination({
    required this.relativeDirectory,
    required this.filename,
  });

  final String relativeDirectory;
  final String filename;
}

class DownloadTransferTask {
  const DownloadTransferTask({
    required this.id,
    required this.purpose,
    required this.correlationId,
    required this.remoteUri,
    required this.destination,
    required this.displayName,
    required this.creationTime,
    this.headers = const {},
    this.metadata = const {},
  });

  final String id;
  final DownloadTransferPurpose purpose;

  /// Stable application-owned identifier used to correlate this transfer with
  /// its offline metadata record.
  final String correlationId;
  final Uri remoteUri;
  final DownloadTransferDestination destination;
  final String displayName;

  /// Determines FIFO order when all tasks have the same transfer priority.
  final DateTime creationTime;

  final Map<String, String> headers;
  final Map<String, String> metadata;
}

sealed class DownloadTransferUpdate {
  const DownloadTransferUpdate({required this.task});

  final DownloadTransferTask task;
}

final class DownloadTransferStatusUpdate extends DownloadTransferUpdate {
  const DownloadTransferStatusUpdate({
    required super.task,
    required this.status,
    this.exception,
    this.responseStatusCode,
    this.mimeType,
  });

  final DownloadTransferStatus status;
  final DownloadTransferException? exception;
  final int? responseStatusCode;
  final String? mimeType;
}

final class DownloadTransferProgressUpdate extends DownloadTransferUpdate {
  const DownloadTransferProgressUpdate({
    required super.task,
    required this.progress,
    this.expectedFileSize,
    this.networkSpeedMegabytesPerSecond,
    this.timeRemaining,
  });

  /// A normalized value from zero through one.
  final double progress;
  final int? expectedFileSize;
  final double? networkSpeedMegabytesPerSecond;
  final Duration? timeRemaining;
}

class DownloadTransferRecord {
  const DownloadTransferRecord({
    required this.task,
    required this.status,
    this.progress,
    this.expectedFileSize,
    this.exception,
  });

  final DownloadTransferTask task;
  final DownloadTransferStatus status;
  final double? progress;
  final int? expectedFileSize;
  final DownloadTransferException? exception;
}

class DownloadTransferRecoveryResult {
  const DownloadTransferRecoveryResult({
    required this.rescheduledTasks,
    required this.failedToRescheduleTasks,
  });

  final List<DownloadTransferTask> rescheduledTasks;
  final List<DownloadTransferTask> failedToRescheduleTasks;
}

class DownloadTransferNotificationMessages {
  const DownloadTransferNotificationMessages({
    required this.runningTitle,
    required this.runningBody,
    required this.failedTitle,
    required this.failedBody,
    required this.cancelActionLabel,
  });

  final String runningTitle;
  final String runningBody;
  final String failedTitle;
  final String failedBody;
  final String cancelActionLabel;
}

class DownloadAlertNotificationMessages {
  const DownloadAlertNotificationMessages({
    required this.channelName,
    required this.channelDescription,
    required this.failedTitle,
    required this.failedBody,
    required this.lowStorageTitle,
    required this.lowStorageBody,
  });

  final String channelName;
  final String channelDescription;
  final String failedTitle;
  final String failedBody;
  final String lowStorageTitle;
  final String lowStorageBody;
}

abstract interface class DownloadAlertNotifications {
  /// Initializes notification channels without requesting permission.
  Future<void> initialize(DownloadAlertNotificationMessages messages);

  Future<void> showDownloadFailures();

  Future<void> showInsufficientStorage();

  Future<void> dispose();
}

abstract interface class DownloadTransfer {
  Stream<DownloadTransferUpdate> get updates;

  /// Configures persistent tracking and resumes updates produced while the
  /// application was suspended. This method does not request permissions.
  Future<void> start(DownloadTransferNotificationMessages messages);

  Future<DownloadNotificationPermissionStatus>
  getNotificationPermissionStatus();

  Future<bool> shouldShowNotificationPermissionRationale();

  Future<DownloadNotificationPermissionStatus> requestNotificationPermission();

  Future<bool> enqueue(DownloadTransferTask task);

  Future<bool> cancel(String taskId);

  Future<bool> cancelAll();

  Future<bool> tasksFinished({String? ignoringTaskId});

  Future<List<DownloadTransferTask>> getActiveTasks();

  Future<List<DownloadTransferRecord>> getRecords();

  Future<DownloadTransferRecord?> getRecord(String taskId);

  Future<void> deleteRecord(String taskId);

  Future<DownloadTransferRecoveryResult> rescheduleMissingTasks();

  Future<String> resolveFilePath(DownloadTransferDestination destination);

  Future<bool> fileExists(DownloadTransferDestination destination);

  /// Returns the current destination file size, or null when it does not
  /// exist.
  Future<int?> fileSize(DownloadTransferDestination destination);

  /// Removes the destination file if it exists. Returns whether a file was
  /// removed.
  Future<bool> removeFile(DownloadTransferDestination destination);

  Future<void> dispose();
}
