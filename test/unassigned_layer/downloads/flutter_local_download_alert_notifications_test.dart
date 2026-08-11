import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/flutter_local_download_alert_notifications.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initializes without requesting and shows localized storage alert',
    () async {
      final client = _FakeLocalDownloadNotificationClient();
      final errorReporter = _FakeErrorReporter();
      final notifications = FlutterLocalDownloadAlertNotifications(
        errorReporter: errorReporter,
        client: client,
      );

      await notifications.initialize(_messages);
      await notifications.showInsufficientStorage();
      await notifications.showDownloadFailures();

      expect(client.initializeCount, 1);
      expect(client.insufficientStorageMessages, [_messages]);
      expect(client.downloadFailureMessages, [_messages]);
      expect(
        errorReporter.breadcrumbs.map((breadcrumb) => breadcrumb.message),
        [
          'Insufficient download storage notification shown',
          'Download failures notification shown',
        ],
      );
    },
  );

  test('does not show after disposal', () async {
    final client = _FakeLocalDownloadNotificationClient();
    final notifications = FlutterLocalDownloadAlertNotifications(
      errorReporter: _FakeErrorReporter(),
      client: client,
    );
    await notifications.initialize(_messages);

    await notifications.dispose();
    await notifications.showInsufficientStorage();

    expect(client.insufficientStorageMessages, isEmpty);
    expect(client.downloadFailureMessages, isEmpty);
  });

  test(
    'accepts false initialization result when permissions are deferred',
    () async {
      final client = _FakeLocalDownloadNotificationClient()
        ..initializeResult = false;
      final notifications = FlutterLocalDownloadAlertNotifications(
        errorReporter: _FakeErrorReporter(),
        client: client,
      );

      await notifications.initialize(_messages);
      await notifications.showDownloadFailures();

      expect(client.initializeCount, 1);
      expect(client.downloadFailureMessages, [_messages]);
    },
  );
}

const _messages = DownloadAlertNotificationMessages(
  channelName: 'Download alerts',
  channelDescription: 'Important offline download alerts',
  failedTitle: 'Downloads finished',
  failedBody: 'Failed to download some tracks.',
  lowStorageTitle: 'Not enough storage',
  lowStorageBody: 'Downloads were stopped to keep free space available.',
);

class _FakeLocalDownloadNotificationClient
    implements LocalDownloadNotificationClient {
  int initializeCount = 0;
  bool? initializeResult = true;
  final List<DownloadAlertNotificationMessages> downloadFailureMessages = [];
  final List<DownloadAlertNotificationMessages> insufficientStorageMessages =
      [];

  @override
  Future<bool?> initialize() async {
    initializeCount++;

    return initializeResult;
  }

  @override
  Future<void> showDownloadFailures(
    DownloadAlertNotificationMessages messages,
  ) async {
    downloadFailureMessages.add(messages);
  }

  @override
  Future<void> showInsufficientStorage(
    DownloadAlertNotificationMessages messages,
  ) async {
    insufficientStorageMessages.add(messages);
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
