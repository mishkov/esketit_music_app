import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FlutterLocalDownloadAlertNotifications
    implements DownloadAlertNotifications {
  FlutterLocalDownloadAlertNotifications({
    required ErrorReporter errorReporter,
    LocalDownloadNotificationClient? client,
  }) : _errorReporter = errorReporter,
       _client = client ?? LocalDownloadNotificationClientDefault();

  static const int insufficientStorageNotificationId = 74001;
  static const int downloadFailuresNotificationId = 74002;
  static const String alertChannelId = 'offline_download_alerts';

  final ErrorReporter _errorReporter;
  final LocalDownloadNotificationClient _client;

  DownloadAlertNotificationMessages? _messages;
  bool _disposed = false;

  @override
  Future<void> initialize(DownloadAlertNotificationMessages messages) async {
    if (_disposed) {
      throw StateError(
        'Disposed download alert notifications cannot initialize',
      );
    }
    // Darwin returns false when initialization deliberately does not request
    // notification permissions. The plugin is still ready to show alerts once
    // permission is requested later.
    await _client.initialize();
    _messages = messages;
  }

  @override
  Future<void> showInsufficientStorage() async {
    if (_disposed) {
      return;
    }
    final messages = _messages;
    if (messages == null) {
      throw StateError('Download alert notifications are not initialized');
    }
    await _client.showInsufficientStorage(messages);
    await _addBreadcrumb('Insufficient download storage notification shown');
  }

  @override
  Future<void> showDownloadFailures() async {
    if (_disposed) {
      return;
    }
    final messages = _messages;
    if (messages == null) {
      throw StateError('Download alert notifications are not initialized');
    }
    await _client.showDownloadFailures(messages);
    await _addBreadcrumb('Download failures notification shown');
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _messages = null;
  }

  Future<void> _addBreadcrumb(String message) async {
    try {
      await _errorReporter.addBreadcrumb(Breadcrumb(message: message));
    } catch (_) {
      // Reporting must never change notification behavior.
    }
  }
}

abstract interface class LocalDownloadNotificationClient {
  Future<bool?> initialize();

  Future<void> showDownloadFailures(DownloadAlertNotificationMessages messages);

  Future<void> showInsufficientStorage(
    DownloadAlertNotificationMessages messages,
  );
}

class LocalDownloadNotificationClientDefault
    implements LocalDownloadNotificationClient {
  LocalDownloadNotificationClientDefault({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<bool?> initialize() {
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    return _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
  }

  @override
  Future<void> showDownloadFailures(
    DownloadAlertNotificationMessages messages,
  ) {
    return _plugin.show(
      id: FlutterLocalDownloadAlertNotifications.downloadFailuresNotificationId,
      title: messages.failedTitle,
      body: messages.failedBody,
      notificationDetails: _alertDetails(messages),
    );
  }

  @override
  Future<void> showInsufficientStorage(
    DownloadAlertNotificationMessages messages,
  ) {
    return _plugin.show(
      id: FlutterLocalDownloadAlertNotifications
          .insufficientStorageNotificationId,
      title: messages.lowStorageTitle,
      body: messages.lowStorageBody,
      notificationDetails: _alertDetails(messages),
    );
  }

  NotificationDetails _alertDetails(
    DownloadAlertNotificationMessages messages,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        FlutterLocalDownloadAlertNotifications.alertChannelId,
        messages.channelName,
        channelDescription: messages.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.error,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
  }
}
