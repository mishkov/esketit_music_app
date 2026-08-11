import 'dart:async';

import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/downloads/delete_all_downloads_dialog.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/library/downloaded_library_section.dart';
import 'package:esketit_music_app/ui/library/library_preference_tiles_row.dart';
import 'package:esketit_music_app/ui/library/playlists_library_section.dart';
import 'package:esketit_music_app/ui/playlists/playlist_details_screen.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyLibraryPage extends StatelessWidget {
  const MyLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, authState) {
        return BlocBuilder<PlaylistsBloc, PlaylistsState>(
          builder: (context, state) {
            final favoritesPlaylist = state.playlists
                .where((playlist) => playlist.kind == PlaylistKind.favorites)
                .firstOrNull;
            final dislikesPlaylist = state.playlists
                .where((playlist) => playlist.kind == PlaylistKind.dislikes)
                .firstOrNull;
            final customPlaylists = state.playlists
                .where((playlist) => playlist.kind == PlaylistKind.custom)
                .toList(growable: false);
            final content = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                LibraryPreferenceTilesRow(
                  isAuthenticated: authState.isAuthenticated,
                  isLoading: state.isLoadingPlaylists,
                  favoritesTrackCount: favoritesPlaylist?.trackCount ?? 0,
                  dislikesTrackCount: dislikesPlaylist?.trackCount ?? 0,
                  onFavoritesTap: () => _openSystemPlaylist(
                    context,
                    isAuthenticated: authState.isAuthenticated,
                    playlistId: favoritesPlaylist?.id,
                  ),
                  onDislikesTap: () => _openSystemPlaylist(
                    context,
                    isAuthenticated: authState.isAuthenticated,
                    playlistId: dislikesPlaylist?.id,
                  ),
                ),
                const SizedBox(height: 24),
                PlaylistsLibrarySection(
                  isAuthenticated: authState.isAuthenticated,
                  isLoading: state.isLoadingPlaylists,
                  hasError: state.playlistsErrorMessage != null,
                  isSubmittingPlaylist: state.isSubmittingPlaylist,
                  playlists: customPlaylists,
                  onCreatePlaylist: () => _onCreatePlaylistSelected(
                    context,
                    isAuthenticated: authState.isAuthenticated,
                  ),
                  onGuestPromptTap: () => _showLoginRequiredPrompt(context),
                ),
                const SizedBox(height: 24),
                _downloadedLibrarySection(context),
              ],
            );

            if (!authState.isAuthenticated) {
              return content;
            }

            return RefreshIndicator(
              onRefresh: () => _refreshPlaylists(context),
              child: content,
            );
          },
        );
      },
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final input = await showDialog(
      context: context,
      builder: (context) => const PlaylistEditorDialog(),
    );

    if (input is! PlaylistEditorResult || !context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(
      CreatePlaylistRequested(input.input, coverFile: input.coverFile),
    );
  }

  Future<void> _refreshPlaylists(BuildContext context) async {
    context.read<PlaylistsBloc>().add(const LoadPlaylists(forceRefresh: true));
  }

  void _onCreatePlaylistSelected(
    BuildContext context, {
    required bool isAuthenticated,
  }) {
    if (!isAuthenticated) {
      _showLoginRequiredPrompt(context);

      return;
    }

    unawaited(_createPlaylist(context));
  }

  void _openSystemPlaylist(
    BuildContext context, {
    required bool isAuthenticated,
    required int? playlistId,
  }) {
    if (!isAuthenticated) {
      _showLoginRequiredPrompt(context);

      return;
    }

    if (playlistId == null) {
      context.read<PlaylistsBloc>().add(
        const LoadPlaylists(forceRefresh: true),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlaylistDetailsScreen(playlistId: playlistId),
      ),
    );
  }

  void _showLoginRequiredPrompt(BuildContext context) {
    LoginRequiredPromptScope.of(context).show();
  }

  Widget _downloadedLibrarySection(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      buildWhen: (previous, current) =>
          previous.availability != current.availability ||
          previous.library != current.library ||
          previous.queue != current.queue,
      builder: (context, state) {
        if (!state.isSupported) {
          return const SizedBox.shrink();
        }
        final library = state.library;
        final hasAnything = library.tracks.isNotEmpty || state.queue.hasWork;

        return DownloadedLibrarySection(
          trackCount: library.tracks.length,
          authorCount: library.authors.length,
          albumCount: library.albums.length,
          playlistCount: library.playlists.length,
          onTracksTap: () =>
              Navigator.of(context).pushNamed(downloadedTracksRoutePath),
          onAuthorsTap: () =>
              Navigator.of(context).pushNamed(downloadedAuthorsRoutePath),
          onAlbumsTap: () =>
              Navigator.of(context).pushNamed(downloadedAlbumsRoutePath),
          onPlaylistsTap: () =>
              Navigator.of(context).pushNamed(downloadedPlaylistsRoutePath),
          onDeleteAll: hasAnything
              ? () => _confirmDeleteAllDownloads(
                  context,
                  trackCount: library.tracks.length,
                )
              : null,
        );
      },
    );
  }

  Future<void> _confirmDeleteAllDownloads(
    BuildContext context, {
    required int trackCount,
  }) async {
    final shouldDelete = await DeleteAllDownloadsDialog.show(
      context,
      trackCount: trackCount,
      knownSizeBytes: null,
    );
    if (shouldDelete && context.mounted) {
      context.read<DownloadsBloc>().add(const DeleteAllDownloadsRequested());
    }
  }
}
