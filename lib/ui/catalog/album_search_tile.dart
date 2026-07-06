import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AlbumSearchTile extends StatelessWidget {
  const AlbumSearchTile({required this.album, this.onTap, super.key});

  final Album album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              ? l10n.albumTypeLabel
              : l10n.albumWithReleaseDateLabel(
                  context.formatReleaseDate(album.releaseDate!),
                ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openDetails(context),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    onTap?.call();
    openAlbumDetails(context, album);
  }
}
