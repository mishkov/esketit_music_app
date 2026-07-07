import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:flutter/material.dart';

class ExpandedAuthorAlbumInfo extends StatelessWidget {
  const ExpandedAuthorAlbumInfo({required this.album, super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final releaseDate = album.releaseDate;
    final releaseDateLabel = releaseDate == null
        ? context.l10n.releaseDateUnknown
        : context.formatReleaseDate(releaseDate);
    final metadata = [
      context.l10n.albumTypeLabel,
      releaseDateLabel,
      context.l10n.playlistTracksCount(album.trackIds.length),
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(album.title, style: titleStyle),
        const SizedBox(height: 8),
        Text(metadata, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
