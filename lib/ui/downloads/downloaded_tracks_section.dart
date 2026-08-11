import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_track_card.dart';
import 'package:flutter/material.dart';

class DownloadedTracksSection extends StatelessWidget {
  const DownloadedTracksSection({
    required this.tracks,
    required this.emptyMessage,
    super.key,
  });

  final List<Track> tracks;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final queue = downloadedPlaybackQueue(tracks);

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.tracksTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (tracks.isEmpty) Text(emptyMessage),
            ...tracks.map(
              (track) => DownloadedTrackCard(
                key: ValueKey(track.id),
                track: track,
                queue: queue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
