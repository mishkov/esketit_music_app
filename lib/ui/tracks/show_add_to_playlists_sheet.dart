import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/tracks/playlist_picker_sheet.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAddToPlaylistsSheet({
  required BuildContext context,
  required Track track,
}) async {
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

  if (result == null || !context.mounted) {
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
