import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:flutter/material.dart';

class AlbumTracksSection extends StatelessWidget {
  const AlbumTracksSection({
    required this.tracks,
    required this.tracksQueue,
    super.key,
  });

  final List<Track> tracks;
  final List<Track> tracksQueue;

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
              l10n.tracksTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (tracks.isEmpty) Text(l10n.noTracksInAlbumYet),
            ...tracks.map((track) {
              return TrackListCard(track: track, queue: tracksQueue);
            }),
          ],
        ),
      ),
    );
  }
}
