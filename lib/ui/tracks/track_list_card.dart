import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/tracks/playlist_picker_sheet.dart';
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
    this.showImage = false,
    super.key,
  });

  final Track track;
  final List<Track> queue;
  final AutoplayContext? autoplayContext;
  final int? playlistIdForRemoval;
  final bool showAddToPlaylistsAction;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final isSelected = playerState.selectedTrack == track;

        return BlocBuilder<PlaylistsBloc, PlaylistsState>(
          builder: (context, playlistState) {
            final effectiveIsFavorite =
                playlistState.favoriteOverrides[track.id] ?? track.isFavorite;
            final favoritePending = playlistState.pendingFavoriteTrackIds
                .contains(track.id);
            final playlistsPending = playlistState.pendingTrackPlaylistActionIds
                .contains(track.id);

            return Opacity(
              opacity: track.isAvailable ? 1 : 0.6,
              child: Card.outlined(
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
                              imageUrl: _trackImageUrl(track),
                              icon: Icons.music_note_rounded,
                            ),
                          ),
                        )
                      : null,
                  title: Text(track.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      track.authors
                          .map((author) => author.currentName)
                          .join(', '),
                      if (!track.isAvailable) l10n.trackNotAvailable,
                    ].where((part) => part.isNotEmpty).join(' • '),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
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
                      ),
                      if (showAddToPlaylistsAction)
                        IconButton(
                          tooltip: l10n.addToPlaylistsTooltip,
                          onPressed: playlistsPending
                              ? null
                              : () => _showAddToPlaylistsSheet(context),
                          icon: const Icon(Icons.playlist_add_rounded),
                        ),
                      if (playlistIdForRemoval != null)
                        IconButton(
                          tooltip: l10n.removeFromPlaylistTooltip,
                          onPressed: playlistsPending
                              ? null
                              : () => context.read<PlaylistsBloc>().add(
                                  RemoveTrackFromPlaylistRequested(
                                    trackId: track.id,
                                    playlistId: playlistIdForRemoval!,
                                  ),
                                ),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                    ],
                  ),
                  onTap: track.isAvailable
                      ? () => context.read<PlayerBloc>().add(
                          PlayTrack(
                            track,
                            queue: queue,
                            autoplayContext: autoplayContext,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _trackImageUrl(Track track) {
    final image = track.image;
    if (image is! HttpFile) {
      return null;
    }
    final value = image.uri.toString();

    return value.isEmpty ? null : value;
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

  Future<void> _showAddToPlaylistsSheet(BuildContext context) async {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    final playlistsBloc = context.read<PlaylistsBloc>();
    if (playlistsBloc.state.playlists.isEmpty &&
        !playlistsBloc.state.isLoadingPlaylists) {
      playlistsBloc.add(const LoadPlaylists());
    }

    _loadMissingPlaylistDetails(playlistsBloc);

    final result = await showModalBottomSheet<PlaylistPickerResult>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return BlocConsumer<PlaylistsBloc, PlaylistsState>(
          listener: (context, state) =>
              _loadMissingPlaylistDetails(context.read<PlaylistsBloc>()),
          builder: (context, state) {
            final playlists = state.playlists
                .where((playlist) => !playlist.isFavorites)
                .toList(growable: false);
            final selectedPlaylistIds = _playlistIdsContainingTrack(
              state,
              playlists,
              track.id,
            );

            return PlaylistPickerSheet(
              playlists: playlists,
              initialSelectedPlaylistIds: selectedPlaylistIds,
              isLoading:
                  state.isLoadingPlaylists ||
                  _isLoadingPlaylistMembership(state, playlists),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final playlistIdsToAdd = result.selectedPlaylistIds
        .difference(result.initialPlaylistIds)
        .toList(growable: false);
    final playlistIdsToRemove = result.initialPlaylistIds
        .difference(result.selectedPlaylistIds)
        .toList(growable: false);
    if (playlistIdsToAdd.isEmpty && playlistIdsToRemove.isEmpty) {
      return;
    }

    context.read<PlaylistsBloc>().add(
      UpdateTrackPlaylistsRequested(
        trackId: track.id,
        addPlaylistIds: playlistIdsToAdd,
        removePlaylistIds: playlistIdsToRemove,
      ),
    );
  }

  Set<int> _playlistIdsContainingTrack(
    PlaylistsState state,
    List<Playlist> playlists,
    int trackId,
  ) {
    return playlists
        .where(
          (playlist) =>
              state.playlistTracksById[playlist.id]?.any(
                (track) => track.id == trackId,
              ) ??
              false,
        )
        .map((playlist) => playlist.id)
        .toSet();
  }

  bool _isLoadingPlaylistMembership(
    PlaylistsState state,
    List<Playlist> playlists,
  ) {
    return playlists.any(
      (playlist) =>
          playlist.trackCount > 0 &&
          !state.playlistTracksById.containsKey(playlist.id) &&
          !state.playlistErrorMessages.containsKey(playlist.id),
    );
  }

  void _loadMissingPlaylistDetails(PlaylistsBloc playlistsBloc) {
    final state = playlistsBloc.state;
    for (final playlist in state.playlists.where(
      (playlist) => !playlist.isFavorites && playlist.trackCount > 0,
    )) {
      if (state.playlistTracksById.containsKey(playlist.id) ||
          state.loadingPlaylistIds.contains(playlist.id) ||
          state.playlistErrorMessages.containsKey(playlist.id)) {
        continue;
      }

      playlistsBloc.add(LoadPlaylistDetails(playlist.id));
    }
  }
}
