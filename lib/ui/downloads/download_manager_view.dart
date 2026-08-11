import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/download_manager_job_tile.dart';
import 'package:esketit_music_app/ui/downloads/download_manager_section.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:flutter/material.dart';

class DownloadManagerView extends StatelessWidget {
  const DownloadManagerView({
    required this.queue,
    required this.onCancelJob,
    super.key,
  });

  final DownloadQueueSnapshot queue;
  final ValueChanged<int> onCancelJob;

  @override
  Widget build(BuildContext context) {
    final current = queue.current;
    if (current == null && queue.queued.isEmpty && queue.failures.isEmpty) {
      return Center(child: Text(context.l10n.noDownloadActivity));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (current != null)
          DownloadManagerSection(
            title: context.l10n.currentDownloadSectionTitle,
            children: [
              DownloadManagerJobTile(
                job: current,
                onCancel: () => onCancelJob(current.id),
              ),
            ],
          ),
        if (current != null && queue.queued.isNotEmpty)
          const SizedBox(height: 24),
        if (queue.queued.isNotEmpty)
          DownloadManagerSection(
            title: context.l10n.queuedDownloadsSectionTitle,
            children: queue.queued
                .map(
                  (job) => DownloadManagerJobTile(
                    key: ValueKey(job.id),
                    job: job,
                    onCancel: () => onCancelJob(job.id),
                  ),
                )
                .toList(growable: false),
          ),
        if ((current != null || queue.queued.isNotEmpty) &&
            queue.failures.isNotEmpty)
          const SizedBox(height: 24),
        if (queue.failures.isNotEmpty)
          DownloadManagerSection(
            title: context.l10n.failedDownloadsSectionTitle,
            children: queue.failures
                .map(
                  (job) =>
                      DownloadManagerJobTile(key: ValueKey(job.id), job: job),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}
