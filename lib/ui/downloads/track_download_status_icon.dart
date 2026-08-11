import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter/material.dart';

enum TrackDownloadUiStatus { queued, downloading, downloaded, error }

class TrackDownloadStatusIcon extends StatelessWidget {
  const TrackDownloadStatusIcon({
    required this.status,
    this.size,
    this.color,
    super.key,
  });

  factory TrackDownloadStatusIcon.forJobState({
    required DownloadJobState state,
    double? size,
    Color? color,
    Key? key,
  }) {
    final status = switch (state) {
      DownloadJobState.queued ||
      DownloadJobState.waitingToRetry => TrackDownloadUiStatus.queued,
      DownloadJobState.downloading => TrackDownloadUiStatus.downloading,
      DownloadJobState.failed => TrackDownloadUiStatus.error,
    };

    return TrackDownloadStatusIcon(
      key: key,
      status: status,
      size: size,
      color: color,
    );
  }

  final TrackDownloadUiStatus status;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final icon = switch (status) {
      TrackDownloadUiStatus.queued ||
      TrackDownloadUiStatus.downloading => Icons.downloading_rounded,
      TrackDownloadUiStatus.downloaded => Icons.offline_pin_rounded,
      TrackDownloadUiStatus.error => Icons.error_outline_rounded,
    };
    final tooltip = switch (status) {
      TrackDownloadUiStatus.queued => l10n.trackDownloadQueuedTooltip,
      TrackDownloadUiStatus.downloading => l10n.trackDownloadingTooltip,
      TrackDownloadUiStatus.downloaded => l10n.trackDownloadedTooltip,
      TrackDownloadUiStatus.error => l10n.trackDownloadFailedTooltip,
    };

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: size, color: color),
    );
  }
}
