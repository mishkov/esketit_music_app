import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/ui/catalog/album_search_tile.dart';
import 'package:esketit_music_app/ui/catalog/author_search_tile.dart';
import 'package:esketit_music_app/ui/catalog/playlist_search_tile.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class SearchCatalogView extends StatelessWidget {
  const SearchCatalogView({
    required this.state,
    required this.selectedTrackExists,
    required this.scrollController,
    super.key,
  });

  final CatalogState state;
  final bool selectedTrackExists;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final safeResults = state.searchResults;
    final items = safeResults?.items ?? const <CatalogSearchResultItem>[];

    if (state.isLoadingSearch && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchErrorMessage != null && items.isEmpty) {
      return Center(child: Text(state.searchErrorMessage!));
    }

    if (items.isEmpty) {
      return Center(child: Text(l10n.noResultsFound(state.searchQuery.trim())));
    }

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: selectedTrackExists ? 100 : 16,
      ),
      children: [
        Text(
          l10n.searchResultsCount(safeResults?.totalItems ?? items.length),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return switch (item.type) {
            CatalogSearchResultType.author => AuthorSearchTile(
              author: item.author!,
            ),
            CatalogSearchResultType.album => AlbumSearchTile(
              album: item.album!,
            ),
            CatalogSearchResultType.track => TrackListCard(
              key: ValueKey('search-track-${item.track!.id}'),
              track: item.track!,
              queue: [item.track!],
              showImage: true,
              autoplayContext: AutoplayContext(
                sourceType: AutoplaySourceType.track,
                sourceId: item.track!.id,
              ),
            ),
            CatalogSearchResultType.playlist => PlaylistSearchTile(
              playlist: item.playlist!,
            ),
          };
        }),
        if (state.isLoadingSearch)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.searchErrorMessage != null && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(child: Text(state.searchErrorMessage!)),
          ),
        if (!state.hasMoreSearchResults && !state.isLoadingSearch)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text(l10n.endOfResults)),
          ),
      ],
    );
  }
}
