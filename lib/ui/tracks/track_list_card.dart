import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackListCard extends StatelessWidget {
  const TrackListCard({
    required this.track,
    required this.queue,
    this.indexLabel,
    this.playlistIdForRemoval,
    this.showAddToPlaylistsAction = true,
    super.key,
  });

  final Track track;
  final List<Track> queue;
  final Widget? indexLabel;
  final int? playlistIdForRemoval;
  final bool showAddToPlaylistsAction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, playlistState) {
        final effectiveIsFavorite =
            playlistState.favoriteOverrides[track.id] ?? track.isFavorite;
        final favoritePending = playlistState.pendingFavoriteTrackIds.contains(
          track.id,
        );
        final playlistsPending = playlistState.pendingTrackPlaylistActionIds
            .contains(track.id);

        return Opacity(
          opacity: track.isAvailable ? 1 : 0.6,
          child: Card.outlined(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading:
                  indexLabel ??
                  CircleAvatar(
                    child: Icon(
                      track.isAvailable
                          ? Icons.music_note_rounded
                          : Icons.block_rounded,
                    ),
                  ),
              title: Text(track.name),
              subtitle: Text(
                [
                  track.authors.map((author) => author.currentName).join(', '),
                  if (!track.isAvailable) 'Not available',
                ].where((part) => part.isNotEmpty).join(' • '),
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: effectiveIsFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
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
                      tooltip: 'Add to playlists',
                      onPressed: playlistsPending
                          ? null
                          : () => _showAddToPlaylistsSheet(context),
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                  if (playlistIdForRemoval != null)
                    IconButton(
                      tooltip: 'Remove from playlist',
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
                  Icon(
                    track.isAvailable
                        ? Icons.play_arrow_rounded
                        : Icons.do_not_disturb_on_rounded,
                  ),
                ],
              ),
              onTap: track.isAvailable
                  ? () => context.read<PlayerBloc>().add(
                      PlayTrack(track, queue: queue),
                    )
                  : null,
            ),
          ),
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

  Future<void> _showAddToPlaylistsSheet(BuildContext context) async {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();
      return;
    }

    final selectedPlaylistIds = await showModalBottomSheet<List<int>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final playlists = context
            .read<PlaylistsBloc>()
            .state
            .playlists
            .where((playlist) => !playlist.isFavorites)
            .toList(growable: false);
        return _PlaylistPickerSheet(playlists: playlists);
      },
    );

    if (selectedPlaylistIds == null || selectedPlaylistIds.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(
      AddTrackToPlaylistsRequested(
        trackId: track.id,
        playlistIds: selectedPlaylistIds,
      ),
    );
  }
}

class _PlaylistPickerSheet extends StatefulWidget {
  const _PlaylistPickerSheet({required this.playlists});

  final List<Playlist> playlists;

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  final Set<int> _selectedPlaylistIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to playlists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (widget.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Create a custom playlist first.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: widget.playlists
                      .map((playlist) {
                        final isSelected = _selectedPlaylistIds.contains(
                          playlist.id,
                        );
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.trackCount} tracks'),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selectedPlaylistIds.add(playlist.id);
                              } else {
                                _selectedPlaylistIds.remove(playlist.id);
                              }
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.playlists.isEmpty
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop(_selectedPlaylistIds.toList(growable: false)),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
