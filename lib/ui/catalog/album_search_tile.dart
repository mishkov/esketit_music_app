import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AlbumSearchTile extends StatelessWidget {
  const AlbumSearchTile({required this.album, super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(
              imageUrl: albumCoverUrl(album),
              icon: Icons.album_rounded,
            ),
          ),
        ),
        title: Text(album.title),
        subtitle: Text(
          album.releaseDate == null
              ? 'Album'
              : 'Album • ${formatReleaseDate(album.releaseDate!)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => openAlbumDetails(context, album),
      ),
    );
  }
}
