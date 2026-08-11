import 'package:esketit_music_app/ui/downloads/download_manager_screen.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadManagerRouteScreen extends StatelessWidget {
  const DownloadManagerRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      buildWhen: (previous, current) => previous.queue != current.queue,
      builder: (context, state) => DownloadManagerScreen(
        queue: state.queue,
        onCancelJob: _cancelJobCallback(context, state),
      ),
    );
  }

  ValueChanged<int> _cancelJobCallback(
    BuildContext context,
    DownloadsState state,
  ) {
    return (jobId) {
      final jobs = [?state.queue.current, ...state.queue.queued];
      final job = jobs.where((job) => job.id == jobId).firstOrNull;
      if (job != null) {
        context.read<DownloadsBloc>().add(
          CancelTrackDownloadRequested(job.trackId),
        );
      }
    };
  }
}
