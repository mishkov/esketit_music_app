import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/ui/catalog/album_search_tile.dart';
import 'package:esketit_music_app/ui/catalog/author_search_tile.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
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
    final safeResults = state.searchResults;
    final items = safeResults?.items ?? const <CatalogSearchResultItem>[];

    if (state.isLoadingSearch && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchErrorMessage != null && items.isEmpty) {
      return Center(child: Text(state.searchErrorMessage!));
    }

    if (items.isEmpty) {
      return Center(
        child: Text('No results found for "${state.searchQuery.trim()}".'),
      );
    }

    final trackQueue = items
        .where((item) => item.track != null && item.track!.isAvailable)
        .map((item) => item.track!)
        .toList(growable: false);

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
          '${safeResults?.totalItems ?? items.length} result${(safeResults?.totalItems ?? items.length) == 1 ? '' : 's'}',
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
              track: item.track!,
              queue: trackQueue,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('End of results')),
          ),
      ],
    );
  }
}
