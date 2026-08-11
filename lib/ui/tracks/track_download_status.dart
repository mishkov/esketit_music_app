import 'package:esketit_music_app/ui/downloads/track_download_status_icon.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackDownloadStatus extends StatelessWidget {
  const TrackDownloadStatus({required this.trackId, super.key});

  final int trackId;

  @override
  Widget build(BuildContext context) {
    final status = context.select<DownloadsBloc, TrackDownloadState>(
      (bloc) => bloc.state.statusForTrack(trackId),
    );
    final uiStatus = switch (status) {
      TrackDownloadState.notDownloaded => null,
      TrackDownloadState.queued => TrackDownloadUiStatus.queued,
      TrackDownloadState.downloading => TrackDownloadUiStatus.downloading,
      TrackDownloadState.downloaded => TrackDownloadUiStatus.downloaded,
      TrackDownloadState.failed => TrackDownloadUiStatus.error,
    };
    if (uiStatus == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TrackDownloadStatusIcon(status: uiStatus, size: 18),
    );
  }
}
