import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:flutter/material.dart';

class DownloadedPlaylistHeader extends StatelessWidget {
  const DownloadedPlaylistHeader({
    required this.playlist,
    required this.downloadedTrackCount,
    this.downloadAction,
    super.key,
  });

  final Playlist playlist;
  final int downloadedTrackCount;
  final Widget? downloadAction;

  @override
  Widget build(BuildContext context) {
    final icon = switch (playlist.kind) {
      PlaylistKind.custom => Icons.queue_music_rounded,
      PlaylistKind.favorites => Icons.favorite_rounded,
      PlaylistKind.dislikes => Icons.thumb_down_rounded,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RemoteImage(imageUrl: playlist.coverImagePath, icon: icon),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (playlist.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(playlist.description),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(icon),
                      label: Text(
                        context.l10n.playlistTracksCount(downloadedTrackCount),
                      ),
                    ),
                    Chip(
                      label: Text(
                        context.playlistVisibilityLabel(playlist.visibility),
                      ),
                    ),
                  ],
                ),
                if (downloadAction != null) ...[
                  const SizedBox(height: 12),
                  downloadAction!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
