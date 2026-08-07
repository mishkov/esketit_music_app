import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullscreenPlayerControls extends StatelessWidget {
  const FullscreenPlayerControls({
    required this.playerState,
    required this.track,
    required this.showPlaybackButtons,
    required this.showFavoriteButton,
    super.key,
  });

  static const _sideSlotWidth = 64.0;

  final PlayerState playerState;
  final Track track;
  final bool showPlaybackButtons;
  final bool showFavoriteButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, playlistsState) {
        final effectiveIsFavorite = playlistsState.effectiveIsFavorite(track);
        final effectiveIsDisliked = playlistsState.effectiveIsDisliked(track);
        final preferencePending = playlistsState.isTrackPreferencePending(
          track.id,
        );

        return Row(
          children: [
            SizedBox(
              width: _sideSlotWidth,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showFavoriteButton ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showFavoriteButton,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: effectiveIsDisliked
                          ? l10n.removeFromDislikesTooltip
                          : l10n.addToDislikesTooltip,
                      onPressed: preferencePending
                          ? null
                          : () => _toggleDislike(
                              context,
                              shouldBeDisliked: !effectiveIsDisliked,
                            ),
                      icon: Icon(
                        effectiveIsDisliked
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_outlined,
                      ),
                      iconSize: 32,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showPlaybackButtons ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showPlaybackButtons,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: playerState.hasPreviousTrack
                            ? () => context.read<PlayerBloc>().add(
                                const SkipToPreviousTrackRequested(),
                              )
                            : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 40,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.read<PlayerBloc>().add(const TogglePlay()),
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            playerState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: playerState.hasNextTrack
                            ? () => context.read<PlayerBloc>().add(
                                const SkipToNextTrackRequested(),
                              )
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _sideSlotWidth,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: showFavoriteButton ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showFavoriteButton,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: effectiveIsFavorite
                          ? l10n.removeFromFavoritesTooltip
                          : l10n.addToFavoritesTooltip,
                      onPressed: preferencePending
                          ? null
                          : () => _toggleFavorite(
                              context,
                              shouldBeFavorite: !effectiveIsFavorite,
                              currentIsDisliked: effectiveIsDisliked,
                            ),
                      icon: Icon(
                        effectiveIsFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      iconSize: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleFavorite(
    BuildContext context, {
    required bool shouldBeFavorite,
    required bool currentIsDisliked,
  }) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    context.read<PlaylistsBloc>().add(
      ToggleFavoriteRequested(
        trackId: track.id,
        shouldBeFavorite: shouldBeFavorite,
        currentIsDisliked: currentIsDisliked,
      ),
    );
  }

  void _toggleDislike(BuildContext context, {required bool shouldBeDisliked}) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    context.read<PlaylistsBloc>().add(
      ToggleDislikeRequested(
        trackId: track.id,
        shouldBeDisliked: shouldBeDisliked,
        sourceWasPlaying: playerState.isPlaying,
      ),
    );
  }
}
