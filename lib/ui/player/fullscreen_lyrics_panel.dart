import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/ui/player/fullscreen_synced_lyrics.dart';
import 'package:flutter/material.dart';

class FullscreenLyricsPanel extends StatelessWidget {
  const FullscreenLyricsPanel({required this.lyrics, super.key});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context) {
    if (lyrics.type == TrackLyricsType.synced && lyrics.lines.isNotEmpty) {
      return FullscreenSyncedLyrics(lyrics: lyrics);
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
