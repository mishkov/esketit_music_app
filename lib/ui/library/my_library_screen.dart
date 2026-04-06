import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/ui/playlists/playlist_details_screen.dart';
import 'package:esketit_music_app/ui/playlists/playlist_editor_dialog.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
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
              onRefresh: () async {
                context.read<PlaylistsBloc>().add(
                  const LoadPlaylists(forceRefresh: true),
                );
              },
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
                    return _PlaylistCard(playlist: playlist);
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
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PlaylistDetailsScreen(playlistId: playlist.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: playlist.coverImagePath.isEmpty
                      ? ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Icon(
                            playlist.isFavorites
                                ? Icons.favorite_rounded
                                : Icons.queue_music_rounded,
                            size: 30,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            playlist.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (playlist.isFavorites)
                          const Icon(Icons.favorite_rounded, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playlist.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${playlist.trackCount} tracks • ${_playlistVisibilityText(playlist.visibility)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _playlistVisibilityText(PlaylistVisibility visibility) {
  return switch (visibility) {
    PlaylistVisibility.private => 'Private',
    PlaylistVisibility.public => 'Public',
    PlaylistVisibility.shared => 'Shared',
  };
}
