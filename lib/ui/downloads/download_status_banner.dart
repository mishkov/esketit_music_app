import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/track_download_status_icon.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter/material.dart';

class DownloadStatusBanner extends StatelessWidget {
  const DownloadStatusBanner({
    required this.queue,
    required this.onOpen,
    required this.onClearFailures,
    super.key,
  });

  final DownloadQueueSnapshot queue;
  final VoidCallback onOpen;
  final VoidCallback onClearFailures;

  @override
  Widget build(BuildContext context) {
    if (!queue.shouldShowIndicator) {
      return const SizedBox.shrink();
    }

    final current = queue.current;
    final showsFailures = !queue.hasWork && queue.failures.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: showsFailures
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildLeadingIcon(context, current, showsFailures),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(context, current, showsFailures)),
              if (showsFailures)
                TextButton(
                  onPressed: onClearFailures,
                  child: Text(context.l10n.clearButton),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(
    BuildContext context,
    DownloadJobSnapshot? current,
    bool showsFailures,
  ) {
    if (showsFailures) {
      return TrackDownloadStatusIcon(
        status: TrackDownloadUiStatus.error,
        color: Theme.of(context).colorScheme.onErrorContainer,
      );
    }

    return TrackDownloadStatusIcon.forJobState(
      state: current?.state ?? DownloadJobState.queued,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
    );
  }

  Widget _buildContent(
    BuildContext context,
    DownloadJobSnapshot? current,
    bool showsFailures,
  ) {
    final l10n = context.l10n;
    if (showsFailures) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.downloadsFailedCount(queue.failures.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            l10n.downloadFailuresRemainMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    if (current == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.downloadsQueuedCount(queue.queued.length),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            l10n.downloadWaitingToStart,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          const LinearProgressIndicator(),
        ],
      );
    }

    final progress = current.progress;
    final title = current.state == DownloadJobState.waitingToRetry
        ? l10n.downloadWaitingToRetryTrack(current.trackName)
        : l10n.downloadingTrackName(current.trackName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                progress == null
                    ? l10n.downloadInProgressStatus
                    : l10n.downloadProgressPercent((progress * 100).round()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (queue.queued.isNotEmpty)
              Text(
                l10n.downloadsQueuedCount(queue.queued.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
