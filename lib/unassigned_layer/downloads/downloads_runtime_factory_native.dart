import 'dart:io';

import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/background_download_transfer.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/downloads_runtime.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/flutter_local_download_alert_notifications.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/sqflite_downloads_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<DownloadsRuntime?> createDownloadsRuntime({
  required ErrorReporter errorReporter,
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return null;
  }

  final applicationSupportDirectory = await getApplicationSupportDirectory();
  final storage = await SqfliteDownloadsStorage.open(
    databasePath: path.join(
      applicationSupportDirectory.path,
      'offline_downloads.sqlite',
    ),
    localPathResolver: (relativePath) => path.join(
      applicationSupportDirectory.path,
      path.normalize(relativePath),
    ),
  );

  return DownloadsRuntime(
    storage: storage,
    transfer: BackgroundDownloadTransfer(errorReporter: errorReporter),
    alertNotifications: FlutterLocalDownloadAlertNotifications(
      errorReporter: errorReporter,
    ),
    closeStorage: storage.close,
  );
}
