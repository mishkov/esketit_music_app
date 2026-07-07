import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/ui/authors/expanded_author_album_info.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter/material.dart';

class ExpandedAuthorAlbumHeader extends StatelessWidget {
  const ExpandedAuthorAlbumHeader({required this.album, super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 520;
        final cover = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: false ? 180 : 132,
            child: RemoteImage(
              imageUrl: _albumCoverUrl(album),
              icon: Icons.album_rounded,
            ),
          ),
        );
        final info = ExpandedAuthorAlbumInfo(album: album);

        if (false) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [cover, const SizedBox(height: 16), info],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cover,
            const SizedBox(width: 16),
            Expanded(child: info),
          ],
        );
      },
    );
  }

  String? _albumCoverUrl(Album album) {
    final cover = album.coverImage;
    if (cover is! HttpFile) {
      return null;
    }
    final value = cover.uri.toString();

    return value.isEmpty ? null : value;
  }
}
