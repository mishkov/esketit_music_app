import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/library/downloaded_library_category_tile.dart';
import 'package:flutter/material.dart';

class DownloadedLibrarySection extends StatelessWidget {
  const DownloadedLibrarySection({
    this.trackCount = 0,
    this.authorCount = 0,
    this.albumCount = 0,
    this.playlistCount = 0,
    this.onTracksTap,
    this.onAuthorsTap,
    this.onAlbumsTap,
    this.onPlaylistsTap,
    this.onDeleteAll,
    super.key,
  });

  final int trackCount;
  final int authorCount;
  final int albumCount;
  final int playlistCount;
  final VoidCallback? onTracksTap;
  final VoidCallback? onAuthorsTap;
  final VoidCallback? onAlbumsTap;
  final VoidCallback? onPlaylistsTap;
  final VoidCallback? onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.downloadedTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: l10n.deleteAllDownloadsTooltip,
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              DownloadedLibraryCategoryTile(
                title: l10n.downloadedTracksTitle,
                icon: Icons.music_note_rounded,
                itemCount: trackCount,
                onTap: onTracksTap,
              ),
              const Divider(height: 1),
              DownloadedLibraryCategoryTile(
                title: l10n.downloadedAuthorsTitle,
                icon: Icons.person_rounded,
                itemCount: authorCount,
                onTap: onAuthorsTap,
              ),
              const Divider(height: 1),
              DownloadedLibraryCategoryTile(
                title: l10n.downloadedAlbumsTitle,
                icon: Icons.album_rounded,
                itemCount: albumCount,
                onTap: onAlbumsTap,
              ),
              const Divider(height: 1),
              DownloadedLibraryCategoryTile(
                title: l10n.downloadedPlaylistsTitle,
                icon: Icons.queue_music_rounded,
                itemCount: playlistCount,
                onTap: onPlaylistsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
