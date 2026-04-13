import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/authors/album_tile.dart';
import 'package:flutter/material.dart';

class AuthorAlbumsSection extends StatelessWidget {
  const AuthorAlbumsSection({required this.albums, super.key});

  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.albumsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (albums.isEmpty) Text(l10n.noPublishedAlbumsYet),
            ...albums.map((album) => AlbumTile(album: album)),
          ],
        ),
      ),
    );
  }
}
