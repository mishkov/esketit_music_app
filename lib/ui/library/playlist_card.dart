import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/playlists/playlist_details_screen.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:flutter/material.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({required this.playlist, super.key});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openPlaylistDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: playlist.coverImagePath.isEmpty
                      ? ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Icon(
                            playlist.isFavorites
                                ? Icons.favorite_rounded
                                : Icons.queue_music_rounded,
                            size: 30,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            playlist.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (playlist.isFavorites)
                          const Icon(Icons.favorite_rounded, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playlist.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.playlistTracksCount(playlist.trackCount)} • ${context.playlistVisibilityLabel(playlist.visibility)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylistDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailsScreen(playlistId: playlist.id),
      ),
    );
  }
}
