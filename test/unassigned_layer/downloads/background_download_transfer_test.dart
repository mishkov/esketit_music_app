import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/background_download_transfer.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundDownloadTransfer', () {
    test(
      'listens before configuring and starting persistent tracking',
      () async {
        final (:client, :transfer, :errorReporter) = _createTransfer();

        await transfer.start(_notificationMessages);

        expect(client.operations, [
          'listen',
          'configure',
          'configureNotifications',
          'start',
        ]);
        expect(client.messages, _notificationMessages);
      },
    );

    test('rejects a downloader configuration warning', () async {
      final (:client, :transfer, :errorReporter) = _createTransfer();
      client.configurationResults = [(Config.holdingQueue, 'not implemented')];

      await expectLater(
        transfer.start(_notificationMessages),
        throwsA(
          isA<DownloadTransferException>().having(
            (error) => error.description,
            'description',
            contains('not implemented'),
          ),
        ),
      );

      expect(client.operations, ['listen', 'configure']);
      expect(
        errorReporter.breadcrumbs.map((breadcrumb) => breadcrumb.message),
        contains('Download transfer configuration failed'),
      );
    });

    test('enqueues a stable serial task with retry and no pause', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      final creationTime = DateTime.utc(2026, 8, 10, 12);
      final task = DownloadTransferTask(
        id: 'track-audio-42',
        purpose: DownloadTransferPurpose.audio,
        correlationId: '42',
        remoteUri: Uri.parse('https://example.test/audio/42.mp3'),
        destination: const DownloadTransferDestination(
          relativeDirectory: 'offline/audio',
          filename: '42.mp3',
        ),
        displayName: 'Track name',
        creationTime: creationTime,
        headers: const {'Authorization': 'Bearer token'},
        metadata: const {'albumId': '7'},
      );

      expect(await transfer.enqueue(task), isTrue);

      final pluginTask = client.enqueuedTasks.single;
      expect(pluginTask.taskId, task.id);
      expect(pluginTask.url, task.remoteUri.toString());
      expect(pluginTask.filename, '42.mp3');
      expect(pluginTask.directory, 'offline/audio');
      expect(pluginTask.baseDirectory, BaseDirectory.applicationSupport);
      expect(pluginTask.group, BackgroundDownloadTransfer.transferGroup);
      expect(pluginTask.updates, Updates.statusAndProgress);
      expect(pluginTask.requiresWiFi, isFalse);
      expect(pluginTask.retries, 3);
      expect(pluginTask.allowPause, isFalse);
      expect(pluginTask.priority, 5);
      expect(pluginTask.creationTime, creationTime);
      expect(pluginTask.headers, task.headers);
      expect(jsonDecode(pluginTask.metaData), {
        'purpose': 'audio',
        'correlationId': '42',
        'metadata': {'albumId': '7'},
      });
    });

    test('maps file-system failure without exposing plugin types', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      await transfer.start(_notificationMessages);
      final updateFuture = transfer.updates
          .where((update) => update is DownloadTransferStatusUpdate)
          .cast<DownloadTransferStatusUpdate>()
          .first;

      client.addUpdate(
        TaskStatusUpdate(
          _pluginTask(),
          TaskStatus.failed,
          TaskFileSystemException('Insufficient space'),
        ),
      );

      final update = await updateFuture;
      expect(update.status, DownloadTransferStatus.failed);
      expect(update.exception?.kind, DownloadTransferExceptionKind.fileSystem);
      expect(update.task.purpose, DownloadTransferPurpose.artwork);
      expect(update.task.correlationId, 'album-7');
    });

    test('ignores negative plugin progress sentinels', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      await transfer.start(_notificationMessages);
      final updateFuture = transfer.updates
          .where((update) => update is DownloadTransferProgressUpdate)
          .cast<DownloadTransferProgressUpdate>()
          .first;
      final task = _pluginTask();

      client.addUpdate(TaskProgressUpdate(task, progressWaitingToRetry));
      client.addUpdate(TaskProgressUpdate(task, 0.25, 400, 1.5));

      final update = await updateFuture;
      expect(update.progress, 0.25);
      expect(update.expectedFileSize, 400);
      expect(update.networkSpeedMegabytesPerSecond, 1.5);
    });

    test('maps persistent records for startup reconciliation', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      client.records = [
        TaskRecord(
          _pluginTask(),
          TaskStatus.waitingToRetry,
          progressWaitingToRetry,
          -1,
          TaskConnectionException('offline'),
        ),
      ];

      final record = (await transfer.getRecords()).single;

      expect(record.status, DownloadTransferStatus.waitingToRetry);
      expect(record.progress, isNull);
      expect(record.expectedFileSize, isNull);
      expect(record.exception?.kind, DownloadTransferExceptionKind.connection);
    });

    test('requires startup before rescheduling missing native tasks', () async {
      final (:transfer, client: _, errorReporter: _) = _createTransfer();

      await expectLater(transfer.rescheduleMissingTasks(), throwsStateError);
    });

    test('maps the missing-task recovery result', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      client.rescheduledTasks = [_pluginTask()];
      client.failedToRescheduleTasks = [
        _pluginTask().copyWith(taskId: 'artwork-album-8'),
      ];
      await transfer.start(_notificationMessages);

      final result = await transfer.rescheduleMissingTasks();

      expect(result.rescheduledTasks.single.id, 'artwork-album-7');
      expect(result.failedToRescheduleTasks.single.id, 'artwork-album-8');
      expect(client.operations.last, 'rescheduleMissingTasks');
    });

    test('delegates contextual notification permission operations', () async {
      final (:client, :transfer, errorReporter: _) = _createTransfer();
      client.permissionStatus = PermissionStatus.undetermined;
      expect(
        await transfer.getNotificationPermissionStatus(),
        DownloadNotificationPermissionStatus.undetermined,
      );

      client.showRationale = true;
      expect(
        await transfer.shouldShowNotificationPermissionRationale(),
        isTrue,
      );

      client.permissionStatus = PermissionStatus.granted;
      expect(
        await transfer.requestNotificationPermission(),
        DownloadNotificationPermissionStatus.granted,
      );
    });
  });
}

({
  _FakeBackgroundDownloadClient client,
  _FakeErrorReporter errorReporter,
  BackgroundDownloadTransfer transfer,
})
_createTransfer() {
  final client = _FakeBackgroundDownloadClient();
  final errorReporter = _FakeErrorReporter();
  final transfer = BackgroundDownloadTransfer(
    errorReporter: errorReporter,
    client: client,
    missingTaskRecoveryDelay: Duration.zero,
  );
  addTearDown(() async {
    await transfer.dispose();
    await client.dispose();
  });

  return (client: client, errorReporter: errorReporter, transfer: transfer);
}

const _notificationMessages = DownloadTransferNotificationMessages(
  runningTitle: 'Downloading',
  runningBody: 'Download progress',
  failedTitle: 'Download failed',
  failedBody: 'Failed to download some tracks',
  cancelActionLabel: 'Cancel',
);

DownloadTask _pluginTask() {
  return DownloadTask(
    taskId: 'artwork-album-7',
    url: 'https://example.test/artwork/7.jpg',
    filename: '7.jpg',
    directory: 'offline/artwork',
    baseDirectory: BaseDirectory.applicationSupport,
    group: BackgroundDownloadTransfer.transferGroup,
    updates: Updates.statusAndProgress,
    retries: 3,
    metaData: jsonEncode({
      'purpose': 'artwork',
      'correlationId': 'album-7',
      'metadata': {'ownerType': 'album'},
    }),
    displayName: 'Album artwork',
    creationTime: DateTime.utc(2026, 8, 10),
  );
}

class _FakeBackgroundDownloadClient implements BackgroundDownloadClient {
  final StreamController<TaskUpdate> _updatesController =
      StreamController<TaskUpdate>.broadcast();
  final List<String> operations = [];
  final List<DownloadTask> enqueuedTasks = [];

  List<(String, String)> configurationResults = [];
  List<TaskRecord> records = [];
  List<Task> rescheduledTasks = [];
  List<Task> failedToRescheduleTasks = [];
  PermissionStatus permissionStatus = PermissionStatus.granted;
  bool showRationale = false;
  DownloadTransferNotificationMessages? messages;

  @override
  Stream<TaskUpdate> get updates {
    operations.add('listen');

    return _updatesController.stream;
  }

  void addUpdate(TaskUpdate update) => _updatesController.add(update);

  Future<void> dispose() => _updatesController.close();

  @override
  Future<List<(String, String)>> configure(
    DownloadTransferNotificationMessages messages,
  ) async {
    operations.add('configure');
    this.messages = messages;

    return configurationResults;
  }

  @override
  void configureNotifications(DownloadTransferNotificationMessages messages) {
    operations.add('configureNotifications');
    this.messages = messages;
  }

  @override
  Future<void> start() async {
    operations.add('start');
  }

  @override
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<bool> shouldShowNotificationPermissionRationale() async {
    return showRationale;
  }

  @override
  Future<PermissionStatus> requestNotificationPermission() async {
    return permissionStatus;
  }

  @override
  Future<bool> enqueue(DownloadTask task) async {
    enqueuedTasks.add(task);

    return true;
  }

  @override
  Future<bool> cancel(String taskId) async => true;

  @override
  Future<bool> cancelAll() async => true;

  @override
  Future<bool> tasksFinished({String? ignoringTaskId}) async => true;

  @override
  Future<List<Task>> getActiveTasks() async => const [];

  @override
  Future<List<TaskRecord>> getRecords() async => records;

  @override
  Future<TaskRecord?> getRecord(String taskId) async {
    for (final record in records) {
      if (record.taskId == taskId) {
        return record;
      }
    }

    return null;
  }

  @override
  Future<void> deleteRecord(String taskId) async {}

  @override
  Future<(List<Task>, List<Task>)> rescheduleMissingTasks() async {
    operations.add('rescheduleMissingTasks');

    return (rescheduledTasks, failedToRescheduleTasks);
  }
}

class _FakeErrorReporter implements ErrorReporter {
  final List<Breadcrumb> breadcrumbs = [];

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}
