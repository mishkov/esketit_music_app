import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/ui/tracks/synced_track_lyrics_view.dart';
import 'package:flutter/material.dart';

class FullscreenLyricsPanel extends StatelessWidget {
  const FullscreenLyricsPanel({required this.lyrics, super.key});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context) {
    if (lyrics.type == TrackLyricsType.synced && lyrics.lines.isNotEmpty) {
      final textStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        height: 1.18,
      );

      return SyncedTrackLyricsView(
        lyrics: lyrics,
        activeLineAlignment: 0.46,
        activeLineScale: 1.08,
        inactiveLineOpacity: 0.36,
        lineSpacing: 28,
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 160),
        showLeadingBeatIndicator: true,
        textStyle: textStyle,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Text(
        lyrics.displayText,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(height: 1.35),
        textAlign: TextAlign.center,
      ),
    );
  }
}
