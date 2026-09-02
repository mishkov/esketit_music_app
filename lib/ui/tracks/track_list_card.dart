import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/tracks/track_actions_menu.dart';
import 'package:esketit_music_app/ui/tracks/track_download_policy.dart';
import 'package:esketit_music_app/ui/tracks/track_download_status.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackListCard extends StatelessWidget {
  const TrackListCard({
    required this.track,
    required this.queue,
    this.autoplayContext,
    this.playlistIdForRemoval,
    this.showAddToPlaylistsAction = true,
    this.showSaveToDownloadsAction,
    this.showImage = false,
    this.onTap,
    super.key,
  });

  final Track track;
  final List<Track> queue;
  final AutoplayContext? autoplayContext;
  final int? playlistIdForRemoval;
  final bool showAddToPlaylistsAction;
  final bool? showSaveToDownloadsAction;
  final bool showImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final isSelected = playerState.selectedTrack?.id == track.id;

        return BlocBuilder<PlaylistsBloc, PlaylistsState>(
          builder: (context, playlistState) {
            final effectiveIsFavorite = playlistState.effectiveIsFavorite(
              track,
            );
            final effectiveIsDisliked = playlistState.effectiveIsDisliked(
              track,
            );
            final preferencePending = playlistState.isTrackPreferencePending(
              track.id,
            );
            final playlistsPending = playlistState.pendingTrackPlaylistActionIds
                .contains(track.id);

            return Opacity(
              opacity: track.isAvailable ? 1 : 0.6,
              child: Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                shape: isSelected
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      )
                    : null,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: showImage ? const EdgeInsets.all(12) : null,
                  leading: showImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox.square(
                            dimension: 56,
                            child: RemoteImage(
                              file: track.image,
                              icon: Icons.music_note_rounded,
                            ),
                          ),
                        )
                      : null,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TrackDownloadStatus(trackId: track.id),
                    ],
                  ),
                  subtitle: Text(
                    [
                      track.authors
                          .map((author) => author.currentName)
                          .join(', '),
                      if (effectiveIsDisliked) l10n.trackDisliked,
                      if (!track.isAvailable) l10n.trackNotAvailable,
                    ].where((part) => part.isNotEmpty).join(' • '),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
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
                      ),
                      TrackActionsMenu(
                        track: track,
                        effectiveIsDisliked: effectiveIsDisliked,
                        preferencePending: preferencePending,
                        playlistsPending: playlistsPending,
                        playlistIdForRemoval: playlistIdForRemoval,
                        showAddToPlaylistsAction: showAddToPlaylistsAction,
                        showSaveToDownloadsAction:
                            showSaveToDownloadsAction ??
                            showTrackSaveToDownloadsActionByDefault,
                        onToggleDislike: () => _toggleDislike(
                          context,
                          shouldBeDisliked: !effectiveIsDisliked,
                        ),
                      ),
                    ],
                  ),
                  onTap: track.isAvailable
                      ? () {
                          onTap?.call();
                          context.read<PlayerBloc>().add(
                            PlayTrack(
                              track,
                              queue: queue,
                              autoplayContext: autoplayContext,
                            ),
                          );
                        }
                      : null,
                ),
              ),
            );
          },
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

    final queueIndex = queue.indexWhere(
      (queueTrack) => queueTrack.id == track.id,
    );
    final playerState = context.read<PlayerBloc>().state;
    context.read<PlaylistsBloc>().add(
      ToggleDislikeRequested(
        trackId: track.id,
        shouldBeDisliked: shouldBeDisliked,
        sourceContext: autoplayContext,
        sourceQueueIndex: queueIndex < 0 ? null : queueIndex,
        sourceWasPlaying:
            playerState.selectedTrack?.id == track.id && playerState.isPlaying,
      ),
    );
  }
}
