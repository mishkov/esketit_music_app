import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/library/guest_playlists_prompt.dart';
import 'package:esketit_music_app/ui/library/playlist_card.dart';
import 'package:flutter/material.dart';

class PlaylistsLibrarySection extends StatelessWidget {
  const PlaylistsLibrarySection({
    required this.isAuthenticated,
    required this.isLoading,
    required this.hasError,
    required this.isSubmittingPlaylist,
    required this.playlists,
    required this.onCreatePlaylist,
    required this.onGuestPromptTap,
    super.key,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final bool hasError;
  final bool isSubmittingPlaylist;
  final List<Playlist> playlists;
  final VoidCallback onCreatePlaylist;
  final VoidCallback onGuestPromptTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.playlistsSectionTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: l10n.createPlaylistTooltip,
              onPressed: isAuthenticated && isSubmittingPlaylist
                  ? null
                  : onCreatePlaylist,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isAuthenticated) GuestPlaylistsPrompt(onTap: onGuestPromptTap),
        if (isAuthenticated && isLoading && playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (isAuthenticated && hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.playlistsLoadFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (isAuthenticated && !isLoading && !hasError && playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.noPlaylistsYet)),
          ),
        if (isAuthenticated && isLoading && playlists.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (isAuthenticated)
          ...playlists.map((playlist) => PlaylistCard(playlist: playlist)),
      ],
    );
  }
}
