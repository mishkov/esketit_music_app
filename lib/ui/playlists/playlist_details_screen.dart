import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  const PlaylistDetailsScreen({required this.playlistId, super.key});

  final int playlistId;

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlaylistsBloc>().add(LoadPlaylistDetails(widget.playlistId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, state) {
        final playlist = state.playlists
            .where((item) => item.id == widget.playlistId)
            .firstOrNull;
        final tracks = state.playlistTracksById[widget.playlistId];
        final isLoading = state.loadingPlaylistIds.contains(widget.playlistId);
        final errorMessage = state.playlistErrorMessages[widget.playlistId];
        final selectedTrackExists = context.select<PlayerBloc, bool>(
          (bloc) => bloc.state.selectedTrack != null,
        );

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(playlist?.name ?? 'Playlist'),
            actions: [
              if (playlist != null && !playlist.system)
                IconButton(
                  onPressed: state.isSubmittingPlaylist
                      ? null
                      : () => _editPlaylist(context, playlist),
                  icon: const Icon(Icons.edit_rounded),
                ),
              if (playlist != null && !playlist.system)
                IconButton(
                  onPressed: state.deletingPlaylistIds.contains(playlist.id)
                      ? null
                      : () => _deletePlaylist(context, playlist),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: Stack(
            children: [
              if (isLoading && playlist == null)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null && playlist == null)
                Center(child: Text(errorMessage))
              else if (playlist == null)
                const Center(child: Text('Playlist not found.'))
              else
                Padding(
                  padding: EdgeInsets.only(
                    bottom: selectedTrackExists ? 100 : 0,
                  ),
                  child: Column(
                    children: [
                      _PlaylistHeader(playlist: playlist),
                      Expanded(
                        child: tracks == null
                            ? const Center(child: CircularProgressIndicator())
                            : tracks.isEmpty
                            ? const Center(
                                child: Text('This playlist has no tracks yet.'),
                              )
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                onReorder:
                                    state.reorderingPlaylistIds.contains(
                                      playlist.id,
                                    )
                                    ? (_, _) {}
                                    : (oldIndex, newIndex) => _onReorder(
                                        context,
                                        tracks: tracks,
                                        oldIndex: oldIndex,
                                        newIndex: newIndex,
                                      ),
                                itemCount: tracks.length,
                                itemBuilder: (context, index) {
                                  final track = tracks[index];

                                  return TrackListCard(
                                    key: ValueKey(
                                      'playlist-${playlist.id}-track-${track.id}',
                                    ),
                                    track: track,
                                    queue: tracks
                                        .where((item) => item.isAvailable)
                                        .toList(growable: false),
                                    indexLabel: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    playlistIdForRemoval: playlist.isFavorites
                                        ? null
                                        : playlist.id,
                                    showAddToPlaylistsAction:
                                        !playlist.isFavorites,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              if (selectedTrackExists)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: BottomPlayer(),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPlaylist(BuildContext context, Playlist playlist) async {
    final input = await showDialog(
      context: context,
      builder: (context) => PlaylistEditorDialog(
        title: 'Edit playlist',
        submitLabel: 'Save',
        initialName: playlist.name,
        initialDescription: playlist.description,
        initialCoverImagePath: playlist.coverImagePath,
        initialVisibility: playlist.visibility,
      ),
    );

    if (input is! PlaylistUpsertInput || !context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(
      UpdatePlaylistRequested(playlistId: playlist.id, input: input),
    );
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('Delete "${playlist.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(DeletePlaylistRequested(playlist));
    Navigator.of(context).pop();
  }

  void _onReorder(
    BuildContext context, {
    required List<Track> tracks,
    required int oldIndex,
    required int newIndex,
  }) {
    final reorderedTracks = List<Track>.from(tracks);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final movedTrack = reorderedTracks.removeAt(oldIndex);
    reorderedTracks.insert(newIndex, movedTrack);

    context.read<PlaylistsBloc>().add(
      ReorderPlaylistTracksRequested(
        playlistId: widget.playlistId,
        trackIds: reorderedTracks
            .map((track) => track.id)
            .toList(growable: false),
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: playlist.coverImagePath.isEmpty
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        playlist.isFavorites
                            ? Icons.favorite_rounded
                            : Icons.queue_music_rounded,
                        size: 42,
                      ),
                    )
                  : RemoteImage(
                      imageUrl: playlist.coverImagePath,
                      icon: playlist.isFavorites
                          ? Icons.favorite_rounded
                          : Icons.queue_music_rounded,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(playlist.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        playlist.isFavorites
                            ? Icons.favorite_rounded
                            : Icons.queue_music_rounded,
                      ),
                      label: Text('${playlist.trackCount} tracks'),
                    ),
                    Chip(
                      label: Text(
                        _playlistVisibilityLabel(playlist.visibility),
                      ),
                    ),
                    if (playlist.system)
                      const Chip(label: Text('System playlist')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _playlistVisibilityLabel(PlaylistVisibility visibility) {
  return switch (visibility) {
    PlaylistVisibility.private => 'Private',
    PlaylistVisibility.public => 'Public',
    PlaylistVisibility.shared => 'Shared',
  };
}
