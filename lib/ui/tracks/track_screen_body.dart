import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/tracks/track_controls_row.dart';
import 'package:esketit_music_app/ui/tracks/track_lyrics_section.dart';
import 'package:esketit_music_app/ui/tracks/track_progress_section.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class TrackScreenBody extends StatelessWidget {
  const TrackScreenBody({required this.track, required this.state, super.key});

  final Track track;
  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artworkUrl = _trackImageUrl(track);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RemoteImage(
                    imageUrl: artworkUrl,
                    icon: Icons.music_note_rounded,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: (theme.textTheme.headlineSmall?.fontSize ?? 24) * 1.4,
                  child: Marquee(
                    text: track.name,
                    style: theme.textTheme.headlineSmall,
                    blankSpace: 32,
                    velocity: 36,
                    pauseAfterRound: const Duration(milliseconds: 800),
                    startPadding: 0,
                    accelerationDuration: const Duration(milliseconds: 400),
                    decelerationDuration: const Duration(milliseconds: 400),
                  ),
                ),
                Text(
                  _authorsLabel(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const TrackProgressSection(),
          const SizedBox(height: 24),
          TrackControlsRow(state: state, track: track),
          const SizedBox(height: 24),
          TrackLyricsSection(trackId: track.id),
        ],
      ),
    );
  }

  String _authorsLabel(BuildContext context) {
    final joinedAuthors = track.authors
        .map((author) => author.currentName)
        .where((authorName) => authorName.isNotEmpty)
        .join(', ');

    if (joinedAuthors.isNotEmpty) {
      return joinedAuthors;
    }

    return context.l10n.bottomPlayerUnknownArtist;
  }

  String? _trackImageUrl(Track track) {
    final image = track.image;
    if (image is! HttpFile) {
      return null;
    }

    final imageUrl = image.uri.toString();

    return imageUrl.isEmpty ? null : imageUrl;
  }
}
