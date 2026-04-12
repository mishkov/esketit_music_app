import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackControlsRow extends StatelessWidget {
  const TrackControlsRow({required this.state, required this.track, super.key});

  final PlayerState state;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, playlistsState) {
        final effectiveIsFavorite =
            playlistsState.favoriteOverrides[track.id] ?? track.isFavorite;
        final favoritePending = playlistsState.pendingFavoriteTrackIds.contains(
          track.id,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: const SizedBox.shrink()),
            IconButton(
              onPressed: state.hasPreviousTrack
                  ? () => context.read<PlayerBloc>().add(
                      const SkipToPreviousTrackRequested(),
                    )
                  : null,
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 40,
            ),
            FilledButton.tonal(
              onPressed: () =>
                  context.read<PlayerBloc>().add(const TogglePlay()),
              style: FilledButton.styleFrom(shape: const CircleBorder()),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 40,
                ),
              ),
            ),
            IconButton(
              onPressed: state.hasNextTrack
                  ? () => context.read<PlayerBloc>().add(
                      const SkipToNextTrackRequested(),
                    )
                  : null,
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 40,
            ),
            Expanded(
              child: IconButton(
                tooltip: effectiveIsFavorite
                    ? l10n.removeFromFavoritesTooltip
                    : l10n.addToFavoritesTooltip,
                onPressed: favoritePending
                    ? null
                    : () => _toggleFavorite(
                        context,
                        shouldBeFavorite: !effectiveIsFavorite,
                      ),
                icon: Icon(
                  effectiveIsFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                iconSize: 32,
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleFavorite(BuildContext context, {required bool shouldBeFavorite}) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    context.read<PlaylistsBloc>().add(
      ToggleFavoriteRequested(
        trackId: track.id,
        shouldBeFavorite: shouldBeFavorite,
      ),
    );
  }
}
