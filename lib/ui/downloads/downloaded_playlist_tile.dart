import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class DownloadedPlaylistTile extends StatelessWidget {
  const DownloadedPlaylistTile({
    required this.playlist,
    required this.onTap,
    super.key,
  });

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (playlist.kind) {
      PlaylistKind.custom => Icons.queue_music_rounded,
      PlaylistKind.favorites => Icons.favorite_rounded,
      PlaylistKind.dislikes => Icons.thumb_down_rounded,
    };

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(imageUrl: playlist.coverImagePath, icon: icon),
          ),
        ),
        title: Text(playlist.name),
        subtitle: playlist.description.isEmpty
            ? null
            : Text(
                playlist.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
