import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/library/library_preference_tile.dart';
import 'package:flutter/material.dart';

class LibraryPreferenceTilesRow extends StatelessWidget {
  const LibraryPreferenceTilesRow({
    required this.isAuthenticated,
    required this.isLoading,
    required this.favoritesTrackCount,
    required this.dislikesTrackCount,
    required this.onFavoritesTap,
    required this.onDislikesTap,
    super.key,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final int favoritesTrackCount;
  final int dislikesTrackCount;
  final VoidCallback onFavoritesTap;
  final VoidCallback onDislikesTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favoritesSubtitle = isAuthenticated
        ? l10n.playlistTracksCount(favoritesTrackCount)
        : l10n.signInToViewLibraryItem;
    final dislikesSubtitle = isAuthenticated
        ? l10n.playlistTracksCount(dislikesTrackCount)
        : l10n.signInToViewLibraryItem;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 400),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LibraryPreferenceTile(
              title: l10n.dislikesTitle,
              subtitle: dislikesSubtitle,
              icon: Icons.thumb_down_outlined,
              color: Colors.red.shade700,
              onTap: onDislikesTap,
              isLoading: isAuthenticated && isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LibraryPreferenceTile(
              title: l10n.likesTitle,
              subtitle: favoritesSubtitle,
              icon: Icons.favorite_outline_rounded,
              color: Colors.green.shade700,
              onTap: onFavoritesTap,
              isLoading: isAuthenticated && isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
