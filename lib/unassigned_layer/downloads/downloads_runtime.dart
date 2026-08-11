import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:esketit_music_app/use_case/downloads/downloads_storage.dart';

class DownloadsRuntime {
  const DownloadsRuntime({
    required this.storage,
    required this.transfer,
    required this.alertNotifications,
    required this.closeStorage,
  });

  final DownloadsStorage storage;
  final DownloadTransfer transfer;
  final DownloadAlertNotifications alertNotifications;
  final Future<void> Function() closeStorage;
}
