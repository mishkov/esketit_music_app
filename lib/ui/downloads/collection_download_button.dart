import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

enum DownloadCollectionUiKind { album, playlist }

enum CollectionDownloadUiStatus {
  notDownloaded,
  queued,
  downloading,
  downloaded,
  error,
}

class CollectionDownloadButton extends StatelessWidget {
  const CollectionDownloadButton({
    required this.kind,
    required this.status,
    required this.onPressed,
    super.key,
  });

  final DownloadCollectionUiKind kind;
  final CollectionDownloadUiStatus status;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isPending =
        status == CollectionDownloadUiStatus.queued ||
        status == CollectionDownloadUiStatus.downloading;
    final isDownloaded = status == CollectionDownloadUiStatus.downloaded;
    final label = isPending
        ? context.l10n.cancelDownloadButton
        : isDownloaded
        ? context.l10n.removeDownloadButton
        : switch (kind) {
            DownloadCollectionUiKind.album => context.l10n.downloadAlbumButton,
            DownloadCollectionUiKind.playlist =>
              context.l10n.downloadPlaylistButton,
          };
    final icon = isPending
        ? Icons.cancel_outlined
        : isDownloaded
        ? Icons.download_done_rounded
        : Icons.download_rounded;

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
