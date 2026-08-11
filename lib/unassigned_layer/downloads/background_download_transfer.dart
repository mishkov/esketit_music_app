import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:path/path.dart' as path;

class BackgroundDownloadTransfer implements DownloadTransfer {
  BackgroundDownloadTransfer({
    required ErrorReporter errorReporter,
    BackgroundDownloadClient? client,
    Duration missingTaskRecoveryDelay = const Duration(seconds: 5),
  }) : _errorReporter = errorReporter,
       _client = client ?? BackgroundDownloadClientDefault(),
       _missingTaskRecoveryDelay = missingTaskRecoveryDelay;

  static const String transferGroup = 'offlineDownloads';
  static const String notificationGroup = 'offlineDownloadsNotification';

  final ErrorReporter _errorReporter;
  final BackgroundDownloadClient _client;
  final Duration _missingTaskRecoveryDelay;
  final StreamController<DownloadTransferUpdate> _updatesController =
      StreamController<DownloadTransferUpdate>.broadcast();

  StreamSubscription<TaskUpdate>? _pluginUpdatesSubscription;
  Future<void>? _startOperation;
  bool _started = false;
  bool _disposed = false;
  DateTime? _backgroundResumeCompletedAt;

  @override
  Stream<DownloadTransferUpdate> get updates => _updatesController.stream;

  @override
  Future<void> start(DownloadTransferNotificationMessages messages) async {
    if (_disposed) {
      throw StateError('A disposed download transfer cannot be started');
    }
    if (_started) {
      return;
    }

    final existingOperation = _startOperation;
    if (existingOperation != null) {
      return existingOperation;
    }

    final operation = _start(messages);
    _startOperation = operation;
    try {
      await operation;
      _started = true;
    } finally {
      _startOperation = null;
    }
  }

  Future<void> _start(DownloadTransferNotificationMessages messages) async {
    _pluginUpdatesSubscription ??= _client.updates.listen(
      _handlePluginUpdate,
      onError: _handlePluginStreamError,
    );

    try {
      final configurationResults = await _client.configure(messages);
      final configurationProblems = configurationResults
          .where((result) => result.$2.isNotEmpty)
          .toList(growable: false);
      if (configurationProblems.isNotEmpty) {
        final description = configurationProblems
            .map((result) => '${result.$1}: ${result.$2}')
            .join(', ');
        await _addBreadcrumb(
          'Download transfer configuration failed',
          data: {'problems': description},
        );
        throw DownloadTransferException(
          kind: DownloadTransferExceptionKind.general,
          description: description,
        );
      }

      _client.configureNotifications(messages);
      await _client.start();
      _backgroundResumeCompletedAt = DateTime.now();
      await _addBreadcrumb('Download transfer started');
    } catch (_) {
      await _pluginUpdatesSubscription?.cancel();
      _pluginUpdatesSubscription = null;
      rethrow;
    }
  }

  @override
  Future<DownloadNotificationPermissionStatus>
  getNotificationPermissionStatus() async {
    return _mapPermissionStatus(
      await _client.getNotificationPermissionStatus(),
    );
  }

  @override
  Future<bool> shouldShowNotificationPermissionRationale() {
    return _client.shouldShowNotificationPermissionRationale();
  }

  @override
  Future<DownloadNotificationPermissionStatus>
  requestNotificationPermission() async {
    final status = _mapPermissionStatus(
      await _client.requestNotificationPermission(),
    );
    await _addBreadcrumb(
      'Download notification permission requested',
      data: {'status': status.name},
    );

    return status;
  }

  @override
  Future<bool> enqueue(DownloadTransferTask task) async {
    final enqueued = await _client.enqueue(_toPluginTask(task));
    await _addBreadcrumb(
      enqueued
          ? 'Download transfer enqueued'
          : 'Download transfer enqueue failed',
      data: {
        'taskId': task.id,
        'purpose': task.purpose.name,
        'correlationId': task.correlationId,
      },
    );

    return enqueued;
  }

  @override
  Future<bool> cancel(String taskId) async {
    final canceled = await _client.cancel(taskId);
    await _addBreadcrumb(
      canceled
          ? 'Download transfer canceled'
          : 'Download transfer cancel failed',
      data: {'taskId': taskId},
    );

    return canceled;
  }

  @override
  Future<bool> cancelAll() async {
    final canceled = await _client.cancelAll();
    await _addBreadcrumb(
      canceled
          ? 'All download transfers canceled'
          : 'Canceling all download transfers failed',
    );

    return canceled;
  }

  @override
  Future<bool> tasksFinished({String? ignoringTaskId}) {
    return _client.tasksFinished(ignoringTaskId: ignoringTaskId);
  }

  @override
  Future<List<DownloadTransferTask>> getActiveTasks() async {
    final tasks = await _client.getActiveTasks();

    return tasks.map(_fromPluginTask).toList(growable: false);
  }

  @override
  Future<List<DownloadTransferRecord>> getRecords() async {
    final records = await _client.getRecords();

    return records.map(_fromPluginRecord).toList(growable: false);
  }

  @override
  Future<DownloadTransferRecord?> getRecord(String taskId) async {
    final record = await _client.getRecord(taskId);

    return record == null ? null : _fromPluginRecord(record);
  }

  @override
  Future<void> deleteRecord(String taskId) {
    return _client.deleteRecord(taskId);
  }

  @override
  Future<DownloadTransferRecoveryResult> rescheduleMissingTasks() async {
    final backgroundResumeCompletedAt = _backgroundResumeCompletedAt;
    if (!_started || backgroundResumeCompletedAt == null) {
      throw StateError(
        'Download transfer must be started before recovering tasks',
      );
    }
    final elapsed = DateTime.now().difference(backgroundResumeCompletedAt);
    final remainingDelay = _missingTaskRecoveryDelay - elapsed;
    if (remainingDelay > Duration.zero) {
      await Future<void>.delayed(remainingDelay);
    }
    final result = await _client.rescheduleMissingTasks();
    final rescheduledTasks = result.$1
        .map(_fromPluginTask)
        .toList(growable: false);
    final failedToRescheduleTasks = result.$2
        .map(_fromPluginTask)
        .toList(growable: false);
    await _addBreadcrumb(
      'Missing download transfers reconciled',
      data: {
        'rescheduledCount': rescheduledTasks.length,
        'failedCount': failedToRescheduleTasks.length,
      },
    );

    return DownloadTransferRecoveryResult(
      rescheduledTasks: rescheduledTasks,
      failedToRescheduleTasks: failedToRescheduleTasks,
    );
  }

  @override
  Future<String> resolveFilePath(
    DownloadTransferDestination destination,
  ) async {
    _validateDestination(destination);
    final baseDirectory = await Task.baseDirectoryPath(
      BaseDirectory.applicationSupport,
    );
    final resolvedPath = path.normalize(
      path.join(
        baseDirectory,
        destination.relativeDirectory,
        destination.filename,
      ),
    );
    if (!path.isWithin(baseDirectory, resolvedPath)) {
      throw ArgumentError.value(
        destination.relativeDirectory,
        'destination.relativeDirectory',
        'The destination must remain inside application support storage',
      );
    }

    return resolvedPath;
  }

  @override
  Future<bool> fileExists(DownloadTransferDestination destination) async {
    return File(await resolveFilePath(destination)).exists();
  }

  @override
  Future<int?> fileSize(DownloadTransferDestination destination) async {
    final file = File(await resolveFilePath(destination));
    if (!await file.exists()) {
      return null;
    }

    return file.length();
  }

  @override
  Future<bool> removeFile(DownloadTransferDestination destination) async {
    final file = File(await resolveFilePath(destination));
    if (!await file.exists()) {
      return false;
    }
    await file.delete();
    await _addBreadcrumb(
      'Downloaded file removed',
      data: {'relativeDirectory': destination.relativeDirectory},
    );

    return true;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _pluginUpdatesSubscription?.cancel();
    _pluginUpdatesSubscription = null;
    await _updatesController.close();
  }

  void _handlePluginUpdate(TaskUpdate update) {
    if (_disposed || update.task.group != transferGroup) {
      return;
    }
    try {
      switch (update) {
        case TaskStatusUpdate():
          _updatesController.add(
            DownloadTransferStatusUpdate(
              task: _fromPluginTask(update.task),
              status: _mapStatus(update.status),
              exception: _mapException(update.exception),
              responseStatusCode: update.responseStatusCode,
              mimeType: update.mimeType,
            ),
          );
        case TaskProgressUpdate() when update.progress >= 0:
          _updatesController.add(
            DownloadTransferProgressUpdate(
              task: _fromPluginTask(update.task),
              progress: update.progress.clamp(0, 1),
              expectedFileSize: update.hasExpectedFileSize
                  ? update.expectedFileSize
                  : null,
              networkSpeedMegabytesPerSecond: update.hasNetworkSpeed
                  ? update.networkSpeed
                  : null,
              timeRemaining: update.hasTimeRemaining
                  ? update.timeRemaining
                  : null,
            ),
          );
        case TaskProgressUpdate():
          // Negative progress values duplicate status updates in the plugin.
          break;
      }
    } catch (error) {
      unawaited(
        _addBreadcrumb(
          'Download transfer update could not be decoded',
          data: {'error': error.toString()},
        ),
      );
    }
  }

  void _handlePluginStreamError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    _updatesController.addError(error, stackTrace);
    unawaited(
      _addBreadcrumb(
        'Download transfer update stream failed',
        data: {'error': error.toString()},
      ),
    );
  }

  DownloadTask _toPluginTask(DownloadTransferTask task) {
    _validateDestination(task.destination);

    return DownloadTask(
      taskId: task.id,
      url: task.remoteUri.toString(),
      filename: task.destination.filename,
      headers: task.headers,
      directory: task.destination.relativeDirectory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: transferGroup,
      updates: Updates.statusAndProgress,
      requiresWiFi: false,
      retries: 3,
      allowPause: false,
      priority: 5,
      metaData: jsonEncode({
        'purpose': task.purpose.name,
        'correlationId': task.correlationId,
        'metadata': task.metadata,
      }),
      displayName: task.displayName,
      creationTime: task.creationTime,
    );
  }

  DownloadTransferTask _fromPluginTask(Task task) {
    if (task is! DownloadTask ||
        task.baseDirectory != BaseDirectory.applicationSupport) {
      throw StateError('Unexpected task in the offline download group');
    }

    final decodedMetadata = _decodeMetadata(task.metaData);

    return DownloadTransferTask(
      id: task.taskId,
      purpose: decodedMetadata.purpose,
      correlationId: decodedMetadata.correlationId.isEmpty
          ? task.taskId
          : decodedMetadata.correlationId,
      remoteUri: Uri.parse(task.url),
      destination: DownloadTransferDestination(
        relativeDirectory: task.directory,
        filename: task.filename,
      ),
      displayName: task.displayName,
      creationTime: task.creationTime,
      headers: Map.unmodifiable(task.headers),
      metadata: Map.unmodifiable(decodedMetadata.metadata),
    );
  }

  DownloadTransferRecord _fromPluginRecord(TaskRecord record) {
    return DownloadTransferRecord(
      task: _fromPluginTask(record.task),
      status: _mapStatus(record.status),
      progress: record.progress >= 0 ? record.progress.clamp(0, 1) : null,
      expectedFileSize: record.expectedFileSize >= 0
          ? record.expectedFileSize
          : null,
      exception: _mapException(record.exception),
    );
  }

  ({
    DownloadTransferPurpose purpose,
    String correlationId,
    Map<String, String> metadata,
  })
  _decodeMetadata(String encodedMetadata) {
    if (encodedMetadata.isEmpty) {
      return (
        purpose: DownloadTransferPurpose.audio,
        correlationId: '',
        metadata: const {},
      );
    }

    final decoded = jsonDecode(encodedMetadata);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Download transfer metadata is not a map');
    }
    final purposeName = decoded['purpose'] as String?;
    final purpose = DownloadTransferPurpose.values.firstWhere(
      (value) => value.name == purposeName,
      orElse: () => DownloadTransferPurpose.audio,
    );
    final rawMetadata = decoded['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : <String, String>{};

    return (
      purpose: purpose,
      correlationId: decoded['correlationId'] as String? ?? '',
      metadata: metadata,
    );
  }

  void _validateDestination(DownloadTransferDestination destination) {
    if (destination.filename.isEmpty ||
        destination.filename.contains('/') ||
        destination.filename.contains(r'\') ||
        path.basename(destination.filename) != destination.filename) {
      throw ArgumentError.value(
        destination.filename,
        'destination.filename',
        'A non-empty filename without path separators is required',
      );
    }
    final directoryParts = destination.relativeDirectory.split(
      RegExp(r'[/\\]+'),
    );
    if (path.posix.isAbsolute(destination.relativeDirectory) ||
        path.windows.isAbsolute(destination.relativeDirectory) ||
        directoryParts.contains('..')) {
      throw ArgumentError.value(
        destination.relativeDirectory,
        'destination.relativeDirectory',
        'An application-support-relative directory is required',
      );
    }
  }

  Future<void> _addBreadcrumb(
    String message, {
    Map<String, Object?> data = const {},
  }) async {
    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(message: message, data: data),
      );
    } catch (_) {
      // Reporting must never change download behavior.
    }
  }
}

abstract interface class BackgroundDownloadClient {
  Stream<TaskUpdate> get updates;

  Future<List<(String, String)>> configure(
    DownloadTransferNotificationMessages messages,
  );

  void configureNotifications(DownloadTransferNotificationMessages messages);

  Future<void> start();

  Future<PermissionStatus> getNotificationPermissionStatus();

  Future<bool> shouldShowNotificationPermissionRationale();

  Future<PermissionStatus> requestNotificationPermission();

  Future<bool> enqueue(DownloadTask task);

  Future<bool> cancel(String taskId);

  Future<bool> cancelAll();

  Future<bool> tasksFinished({String? ignoringTaskId});

  Future<List<Task>> getActiveTasks();

  Future<List<TaskRecord>> getRecords();

  Future<TaskRecord?> getRecord(String taskId);

  Future<void> deleteRecord(String taskId);

  Future<(List<Task>, List<Task>)> rescheduleMissingTasks();
}

class BackgroundDownloadClientDefault implements BackgroundDownloadClient {
  BackgroundDownloadClientDefault({FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  final FileDownloader _downloader;

  @override
  Stream<TaskUpdate> get updates => _downloader.updates;

  @override
  Future<List<(String, String)>> configure(
    DownloadTransferNotificationMessages messages,
  ) {
    return _downloader.configure(
      globalConfig: const [
        (Config.holdingQueue, (1, 1, 1)),
        (Config.checkAvailableSpace, 128),
        (Config.skipExistingFiles, Config.never),
      ],
      androidConfig: const [
        (Config.runInForeground, Config.always),
        (Config.useCacheDir, Config.whenAble),
      ],
      iOSConfig: [
        const (Config.excludeFromCloudBackup, Config.always),
        (Config.localize, {'Cancel': messages.cancelActionLabel}),
      ],
    );
  }

  @override
  void configureNotifications(DownloadTransferNotificationMessages messages) {
    _downloader.configureNotificationForGroup(
      BackgroundDownloadTransfer.transferGroup,
      running: TaskNotification(messages.runningTitle, messages.runningBody),
      error: TaskNotification(messages.failedTitle, messages.failedBody),
      progressBar: true,
      groupNotificationId: BackgroundDownloadTransfer.notificationGroup,
    );
  }

  @override
  Future<void> start() async {
    await _downloader.trackTasksInGroup(
      BackgroundDownloadTransfer.transferGroup,
      markDownloadedComplete: true,
    );
    await _downloader.resumeFromBackground();
  }

  @override
  Future<PermissionStatus> getNotificationPermissionStatus() {
    return _downloader.permissions.status(PermissionType.notifications);
  }

  @override
  Future<bool> shouldShowNotificationPermissionRationale() {
    return _downloader.permissions.shouldShowRationale(
      PermissionType.notifications,
    );
  }

  @override
  Future<PermissionStatus> requestNotificationPermission() {
    return _downloader.permissions.request(PermissionType.notifications);
  }

  @override
  Future<bool> enqueue(DownloadTask task) => _downloader.enqueue(task);

  @override
  Future<bool> cancel(String taskId) => _downloader.cancelTaskWithId(taskId);

  @override
  Future<bool> cancelAll() {
    return _downloader.cancelAll(
      group: BackgroundDownloadTransfer.transferGroup,
    );
  }

  @override
  Future<bool> tasksFinished({String? ignoringTaskId}) {
    return _downloader.tasksFinished(
      group: BackgroundDownloadTransfer.transferGroup,
      ignoreTaskId: ignoringTaskId,
    );
  }

  @override
  Future<List<Task>> getActiveTasks() {
    return _downloader.allTasks(
      group: BackgroundDownloadTransfer.transferGroup,
    );
  }

  @override
  Future<List<TaskRecord>> getRecords() {
    return _downloader.database.allRecords(
      group: BackgroundDownloadTransfer.transferGroup,
    );
  }

  @override
  Future<TaskRecord?> getRecord(String taskId) async {
    final record = await _downloader.database.recordForId(taskId);

    return record?.group == BackgroundDownloadTransfer.transferGroup
        ? record
        : null;
  }

  @override
  Future<void> deleteRecord(String taskId) {
    return _downloader.database.deleteRecordWithId(taskId);
  }

  @override
  Future<(List<Task>, List<Task>)> rescheduleMissingTasks() async {
    final result = await _downloader.rescheduleKilledTasks();

    return (
      result.$1
          .where(
            (task) => task.group == BackgroundDownloadTransfer.transferGroup,
          )
          .toList(growable: false),
      result.$2
          .where(
            (task) => task.group == BackgroundDownloadTransfer.transferGroup,
          )
          .toList(growable: false),
    );
  }
}

DownloadTransferStatus _mapStatus(TaskStatus status) => switch (status) {
  TaskStatus.enqueued => DownloadTransferStatus.enqueued,
  TaskStatus.running => DownloadTransferStatus.running,
  TaskStatus.complete => DownloadTransferStatus.complete,
  TaskStatus.notFound => DownloadTransferStatus.notFound,
  TaskStatus.failed => DownloadTransferStatus.failed,
  TaskStatus.canceled => DownloadTransferStatus.canceled,
  TaskStatus.waitingToRetry => DownloadTransferStatus.waitingToRetry,
  TaskStatus.paused => DownloadTransferStatus.paused,
};

DownloadNotificationPermissionStatus _mapPermissionStatus(
  PermissionStatus status,
) => switch (status) {
  PermissionStatus.undetermined =>
    DownloadNotificationPermissionStatus.undetermined,
  PermissionStatus.denied => DownloadNotificationPermissionStatus.denied,
  PermissionStatus.granted => DownloadNotificationPermissionStatus.granted,
  PermissionStatus.partial => DownloadNotificationPermissionStatus.partial,
  PermissionStatus.requestError =>
    DownloadNotificationPermissionStatus.requestError,
};

DownloadTransferException? _mapException(TaskException? exception) {
  if (exception == null) {
    return null;
  }
  final kind = switch (exception) {
    TaskFileSystemException() => DownloadTransferExceptionKind.fileSystem,
    TaskUrlException() => DownloadTransferExceptionKind.invalidUrl,
    TaskConnectionException() => DownloadTransferExceptionKind.connection,
    TaskResumeException() => DownloadTransferExceptionKind.resume,
    TaskHttpException() => DownloadTransferExceptionKind.httpResponse,
    TaskException() => DownloadTransferExceptionKind.general,
  };

  return DownloadTransferException(
    kind: kind,
    description: exception.description,
    httpResponseStatusCode: exception is TaskHttpException
        ? exception.httpResponseCode
        : null,
  );
}
