import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeleteAllDownloadsDialog extends StatelessWidget {
  const DeleteAllDownloadsDialog({
    required this.trackCount,
    required this.knownSizeBytes,
    super.key,
  });

  final int trackCount;
  final int? knownSizeBytes;

  static Future<bool> show(
    BuildContext context, {
    required int trackCount,
    required int? knownSizeBytes,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteAllDownloadsDialog(
        trackCount: trackCount,
        knownSizeBytes: knownSizeBytes,
      ),
    );

    return shouldDelete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizeBytes = knownSizeBytes;
    final message = sizeBytes == null
        ? l10n.deleteAllDownloadsMessage(trackCount)
        : l10n.deleteAllDownloadsMessageWithSize(
            trackCount,
            _formatFileSize(context, sizeBytes),
          );

    return AlertDialog(
      title: Text(l10n.deleteAllDownloadsTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteAllDownloadsButton),
        ),
      ],
    );
  }

  String _formatFileSize(BuildContext context, int byteCount) {
    final l10n = context.l10n;
    final safeByteCount = byteCount < 0 ? 0 : byteCount;
    const bytesPerKilobyte = 1024;
    const bytesPerMegabyte = bytesPerKilobyte * 1024;
    const bytesPerGigabyte = bytesPerMegabyte * 1024;
    final numberFormat = NumberFormat('#,##0.#', l10n.localeName);

    if (safeByteCount < bytesPerKilobyte) {
      return l10n.downloadSizeBytes(safeByteCount);
    }
    if (safeByteCount < bytesPerMegabyte) {
      return l10n.downloadSizeKilobytes(
        numberFormat.format(safeByteCount / bytesPerKilobyte),
      );
    }
    if (safeByteCount < bytesPerGigabyte) {
      return l10n.downloadSizeMegabytes(
        numberFormat.format(safeByteCount / bytesPerMegabyte),
      );
    }

    return l10n.downloadSizeGigabytes(
      numberFormat.format(safeByteCount / bytesPerGigabyte),
    );
  }
}
