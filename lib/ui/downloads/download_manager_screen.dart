import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/download_manager_view.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter/material.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({
    required this.queue,
    required this.onCancelJob,
    super.key,
  });

  final DownloadQueueSnapshot queue;
  final ValueChanged<int> onCancelJob;

  @override
  Widget build(BuildContext context) {
    return ScreenSkeleton(
      enableBottomPlayer: false,
      appBar: AppBar(title: Text(context.l10n.downloadManagerTitle)),
      body: DownloadManagerView(queue: queue, onCancelJob: onCancelJob),
    );
  }
}
