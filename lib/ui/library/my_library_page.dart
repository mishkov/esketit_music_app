import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esketit_music_app/ui/library/playlist_card.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';

class MyLibraryPage extends StatelessWidget {
  const MyLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (!authState.isAuthenticated) {
          return Center(child: Text(l10n.signInToSeeYourPlaylists));
        }

        return BlocBuilder<PlaylistsBloc, PlaylistsState>(
          builder: (context, state) {
            if (state.isLoadingPlaylists && state.playlists.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.playlistsErrorMessage != null &&
                state.playlists.isEmpty) {
              return Center(child: Text(state.playlistsErrorMessage!));
            }

            return RefreshIndicator(
              onRefresh: () => _refreshPlaylists(context),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.yourPlaylistsTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: state.isSubmittingPlaylist
                            ? null
                            : () => _createPlaylist(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.newPlaylistButton),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.playlistsDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (state.playlists.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text(l10n.noPlaylistsYet)),
                    ),
                  ...state.playlists.map((playlist) {
                    return PlaylistCard(playlist: playlist);
                  }),
                ],
              ),
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
}
