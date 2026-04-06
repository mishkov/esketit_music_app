import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esketit_music_app/ui/library/playlist_card.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';

// TODO: rename it because actaully this is a page used inside tabbed screen.
class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (!authState.isAuthenticated) {
          return const Center(child: Text('Sign in to see your playlists.'));
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
                          'Your playlists',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: state.isSubmittingPlaylist
                            ? null
                            : () => _createPlaylist(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Favorites is managed automatically. Everything else is fully editable.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (state.playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('No playlists yet. Create your first one.'),
                      ),
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

    if (input is! PlaylistUpsertInput || !context.mounted) {
      return;
    }

    context.read<PlaylistsBloc>().add(CreatePlaylistRequested(input));
  }

  Future<void> _refreshPlaylists(BuildContext context) async {
    context.read<PlaylistsBloc>().add(const LoadPlaylists(forceRefresh: true));
  }
}
