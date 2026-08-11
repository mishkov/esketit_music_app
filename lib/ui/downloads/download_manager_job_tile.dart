import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/track_download_status_icon.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter/material.dart';

class DownloadManagerJobTile extends StatelessWidget {
  const DownloadManagerJobTile({required this.job, this.onCancel, super.key});

  final DownloadJobSnapshot job;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = job.progress;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: TrackDownloadStatusIcon.forJobState(state: job.state),
      title: Text(job.trackName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(_statusLabel(context, progress)),
          if (job.state == DownloadJobState.downloading) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
      trailing: onCancel == null
          ? null
          : IconButton(
              tooltip: context.l10n.cancelDownloadTooltip,
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
            ),
    );
  }

  String _statusLabel(BuildContext context, double? progress) {
    final l10n = context.l10n;

    return switch (job.state) {
      DownloadJobState.queued => l10n.downloadQueuedStatus,
      DownloadJobState.downloading when progress != null =>
        l10n.downloadProgressPercent((progress * 100).round()),
      DownloadJobState.downloading => l10n.downloadInProgressStatus,
      DownloadJobState.waitingToRetry => l10n.downloadWaitingToRetryStatus,
      DownloadJobState.failed => switch (job.failureKind) {
        DownloadFailureKind.network => l10n.downloadFailureNetwork,
        DownloadFailureKind.server => l10n.downloadFailureServer,
        DownloadFailureKind.storage => l10n.downloadFailureStorage,
        DownloadFailureKind.insufficientStorage =>
          l10n.downloadFailureInsufficientStorage,
        DownloadFailureKind.invalidResponse =>
          l10n.downloadFailureInvalidResponse,
        DownloadFailureKind.unknown || null => l10n.downloadFailureUnknown,
      },
    };
  }
}
