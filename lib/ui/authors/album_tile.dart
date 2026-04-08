import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter/material.dart';

class AlbumTile extends StatelessWidget {
  const AlbumTile({required this.album, super.key});

  final Album album;

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
              imageUrl: _albumCoverUrl(album),
              icon: Icons.album_rounded,
            ),
          ),
        ),
        title: Text(album.title),
        subtitle: Text(
          album.releaseDate == null
              ? l10n.releaseDateUnknown
              : context.formatReleaseDate(album.releaseDate!),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openAlbumDetails(context),
      ),
    );
  }

  void _openAlbumDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AlbumDetailsScreen(album: album)),
    );
  }
}

String? _albumCoverUrl(Album album) {
  final cover = album.coverImage;
  if (cover is! HttpFile) {
    return null;
  }
  final value = cover.uri.toString();

  return value.isEmpty ? null : value;
}
