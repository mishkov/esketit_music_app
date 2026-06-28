import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/ui/playlists/playlist_header.dart';
import 'package:esketit_music_app/ui/playlists/playlist_routes.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

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
    final l10n = context.l10n;

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
            title: Text(playlist?.name ?? l10n.playlistFallbackTitle),
            actions: [
              if (_shareUriForPlaylist(playlist) != null)
                IconButton(
                  tooltip: l10n.copyPlaylistLinkTooltip,
                  onPressed: () => _copyPlaylistLink(context, playlist!),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
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
          body: isLoading && playlist == null
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null && playlist == null
              ? Center(child: Text(errorMessage))
              : playlist == null
              ? Center(child: Text(l10n.playlistNotFound))
              : Padding(
                  padding: EdgeInsets.only(
                    bottom: selectedTrackExists ? 100 : 0,
                  ),
                  child: Column(
                    children: [
                      PlaylistHeader(playlist: playlist),
                      Expanded(
                        child: tracks == null
                            ? const Center(child: CircularProgressIndicator())
                            : tracks.isEmpty
                            ? Center(child: Text(l10n.playlistHasNoTracksYet))
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
                                    autoplayContext: AutoplayContext(
                                      sourceType: AutoplaySourceType.playlist,
                                      sourceId: playlist.id,
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
        );
      },
    );
  }

  Future<void> _editPlaylist(BuildContext context, Playlist playlist) async {
    final input = await showDialog(
      context: context,
      builder: (context) => PlaylistEditorDialog(
        title: context.l10n.editPlaylistTitle,
        submitLabel: context.l10n.saveButton,
        initialName: playlist.name,
        initialDescription: playlist.description,
        initialCoverImagePath: playlist.coverImagePath,
        initialVisibility: playlist.visibility,
      ),
    );

    if (input is! PlaylistEditorResult || !context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(
      UpdatePlaylistRequested(
        playlistId: playlist.id,
        input: input.input,
        coverFile: input.coverFile,
      ),
    );
  }

  Future<void> _copyPlaylistLink(
    BuildContext context,
    Playlist playlist,
  ) async {
    final shareUri = _shareUriForPlaylist(playlist);
    if (shareUri == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareUri.toString()));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.playlistLinkCopied)));
  }

  Uri? _shareUriForPlaylist(Playlist? playlist) {
    if (playlist == null) {
      return null;
    }

    return switch (playlist.visibility) {
      PlaylistVisibility.public => shareablePlaylistUri(
        publicPlaylistRoutePath(playlist.id),
      ),
      PlaylistVisibility.shared when playlist.shareToken != null =>
        shareablePlaylistUri(sharedPlaylistRoutePath(playlist.shareToken!)),
      _ => null,
    };
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;

        return AlertDialog(
          title: Text(l10n.deletePlaylistTitle),
          content: Text(l10n.deletePlaylistMessage(playlist.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
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
    final reorderedTracks = List<Track>.of(tracks);
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
