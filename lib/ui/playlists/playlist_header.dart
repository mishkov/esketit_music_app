import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:flutter/material.dart';

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader({required this.playlist, super.key});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: playlist.coverImagePath.isEmpty
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        playlist.isFavorites
                            ? Icons.favorite_rounded
                            : Icons.queue_music_rounded,
                        size: 42,
                      ),
                    )
                  : RemoteImage(
                      imageUrl: playlist.coverImagePath,
                      icon: playlist.isFavorites
                          ? Icons.favorite_rounded
                          : Icons.queue_music_rounded,
                    ),
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
                const SizedBox(height: 8),
                Text(playlist.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        playlist.isFavorites
                            ? Icons.favorite_rounded
                            : Icons.queue_music_rounded,
                      ),
                      label: Text(
                        l10n.playlistTracksCount(playlist.trackCount),
                      ),
                    ),
                    Chip(
                      label: Text(
                        context.playlistVisibilityLabel(playlist.visibility),
                      ),
                    ),
                    if (playlist.system)
                      Chip(label: Text(l10n.systemPlaylistLabel)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
