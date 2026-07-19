import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/player/fullscreen_player_controls.dart';
import 'package:esketit_music_app/ui/shared/animated_collapsible.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/single_line_overflow_marquee_text.dart';
import 'package:esketit_music_app/ui/tracks/track_progress_section.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/settings/fullscreen_player_inactive_controls.dart';
import 'package:flutter/material.dart';

class FullscreenTrackPresentation extends StatelessWidget {
  const FullscreenTrackPresentation({
    required this.areControlsVisible,
    required this.playerState,
    required this.track,
    required this.inactiveControls,
    super.key,
  });

  final bool areControlsVisible;
  final PlayerState playerState;
  final Track track;
  final FullscreenPlayerInactiveControls inactiveControls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showTrackName = areControlsVisible || inactiveControls.showTrackName;
    final showTrackAuthors =
        areControlsVisible || inactiveControls.showTrackAuthors;
    final showTrackProgressIndicator =
        areControlsVisible || inactiveControls.showTrackProgressIndicator;
    final showTrackTiming =
        areControlsVisible || inactiveControls.showTrackTiming;
    final showPlaybackButtons =
        areControlsVisible || inactiveControls.showPlaybackButtons;
    final showFavoriteButton =
        areControlsVisible || inactiveControls.showFavoriteButton;
    final showTrackMetadata = showTrackName || showTrackAuthors;
    final showPlayerControls = showPlaybackButtons || showFavoriteButton;

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
        AnimatedCollapsible(
          visible: showTrackName,
          topPadding: 28,
          child: SizedBox(
            width: double.infinity,
            child: SingleLineOverflowMarqueeText(
              text: track.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AnimatedCollapsible(
          visible: showTrackAuthors,
          topPadding: showTrackName ? 4 : 28,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              _authorsLabel(context, track),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AnimatedCollapsible(
          visible: showTrackProgressIndicator,
          topPadding: showTrackMetadata ? 20 : 28,
          child: TrackProgressSection(showTiming: showTrackTiming),
        ),
        AnimatedCollapsible(
          visible: showPlayerControls,
          topPadding: showTrackProgressIndicator
              ? 16
              : showTrackMetadata
              ? 20
              : 28,
          child: FullscreenPlayerControls(
            playerState: playerState,
            track: track,
            showPlaybackButtons: showPlaybackButtons,
            showFavoriteButton: showFavoriteButton,
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
