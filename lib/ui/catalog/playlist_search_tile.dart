import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:flutter/material.dart';

class PlaylistSearchTile extends StatelessWidget {
  const PlaylistSearchTile({required this.playlist, this.onTap, super.key});

  final Playlist playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(
              imageUrl: playlistCoverUrl(playlist),
              icon: Icons.queue_music_rounded,
            ),
          ),
        ),
        title: Text(playlist.name),
        subtitle: Text(
          '${l10n.playlistTracksCount(playlist.trackCount)} • '
          '${context.playlistVisibilityLabel(playlist.visibility)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openDetails(context),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    onTap?.call();
    openPlaylistDetails(context, playlist);
  }
}
