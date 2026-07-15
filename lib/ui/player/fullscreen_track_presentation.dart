import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/player/fullscreen_player_controls.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/single_line_overflow_marquee_text.dart';
import 'package:esketit_music_app/ui/tracks/track_progress_section.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';

class FullscreenTrackPresentation extends StatelessWidget {
  const FullscreenTrackPresentation({
    required this.areControlsVisible,
    required this.playerState,
    required this.track,
    super.key,
  });

  final bool areControlsVisible;
  final PlayerState playerState;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 460),
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RemoteImage(
                  imageUrl: _trackImageUrl(track),
                  icon: Icons.music_note_rounded,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SingleLineOverflowMarqueeText(
          text: track.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _authorsLabel(context, track),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TrackProgressSection(showTiming: areControlsVisible),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: areControlsVisible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !areControlsVisible,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FullscreenPlayerControls(
                playerState: playerState,
                track: track,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _authorsLabel(BuildContext context, Track track) {
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
