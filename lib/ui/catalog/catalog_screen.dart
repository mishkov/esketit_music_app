import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);
  static const double _lazyLoadTriggerOffset = 240;

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    final catalogBloc = context.read<CatalogBloc>();
    _searchController = TextEditingController(
      text: catalogBloc.state.searchQuery,
    );
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return Stack(
          children: [
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                final activeQuery = state.searchQuery.trim();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchQueryChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search authors, albums, tracks',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: activeQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: activeQuery.isEmpty
                          ? _BrowseCatalogView(
                              selectedTrackExists: selectedTrackExists,
                            )
                          : _SearchCatalogView(
                              state: state,
                              selectedTrackExists: selectedTrackExists,
                              scrollController: _scrollController,
                            ),
                    ),
                  ],
                );
              },
            ),
            if (selectedTrackExists)
              const Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: BottomPlayer(),
              ),
          ],
        );
      },
    );
  }

  void _onSearchQueryChanged(String value) {
    final catalogBloc = context.read<CatalogBloc>();
    catalogBloc.add(CatalogSearchQueryChanged(value));

    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      return;
    }

    _searchDebounce = Timer(_searchDebounceDuration, _loadSearchResults);
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchQueryChanged('');
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final state = context.read<CatalogBloc>().state;
    if (!state.hasActiveSearch ||
        !state.hasMoreSearchResults ||
        state.isLoadingSearch) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > _lazyLoadTriggerOffset) {
      return;
    }

    context.read<CatalogBloc>().add(
      LoadCatalogSearchResults(page: state.searchPage + 1),
    );
  }

  void _loadSearchResults() {
    if (!mounted) {
      return;
    }

    context.read<CatalogBloc>().add(LoadCatalogSearchResults());
  }
}

class _BrowseCatalogView extends StatelessWidget {
  const _BrowseCatalogView({required this.selectedTrackExists});

  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        if (state.isLoadingAuthors && state.authors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.authorsErrorMessage != null && state.authors.isEmpty) {
          return Center(child: Text(state.authorsErrorMessage!));
        }

        if (state.authors.isEmpty) {
          return const Center(child: Text('No published authors yet.'));
        }

        return ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: selectedTrackExists ? 100 : 16,
          ),
          children: [
            Text(
              'Featured Authors',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.authors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final author = state.authors[index];

                  return SizedBox(
                    width: 180,
                    child: _AuthorBrowseCard(author: author),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchCatalogView extends StatelessWidget {
  const _SearchCatalogView({
    required this.state,
    required this.selectedTrackExists,
    required this.scrollController,
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
            CatalogSearchResultType.author => _AuthorSearchTile(
              author: item.author!,
            ),
            CatalogSearchResultType.album => _AlbumSearchTile(
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

class _AuthorBrowseCard extends StatelessWidget {
  const _AuthorBrowseCard({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAuthorDetails(context, author),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RemoteImage(
                imageUrl: author.primaryPhotoUrl,
                icon: Icons.person_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                author.currentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorSearchTile extends StatelessWidget {
  const _AuthorSearchTile({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(
              imageUrl: author.primaryPhotoUrl,
              icon: Icons.person_rounded,
            ),
          ),
        ),
        title: Text(author.currentName),
        subtitle: const Text('Author'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openAuthorDetails(context, author),
      ),
    );
  }
}

class _AlbumSearchTile extends StatelessWidget {
  const _AlbumSearchTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(
              imageUrl: _albumCoverUrl(album),
              icon: Icons.album_rounded,
            ),
          ),
        ),
        title: Text(album.title),
        subtitle: Text(
          album.releaseDate == null
              ? 'Album'
              : 'Album • ${_formatReleaseDate(album.releaseDate!)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openAlbumDetails(context),
      ),
    );
  }

  void _openAlbumDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AlbumDetailsScreen(album: album)),
    );
  }
}

void _openAuthorDetails(BuildContext context, Author author) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AuthorDetailsScreen(author: author),
    ),
  );
}

String? _albumCoverUrl(Album album) {
  final cover = album.coverImage;
  if (cover is! HttpFile) {
    return null;
  }
  final value = cover.uri.toString();

  return value.isEmpty ? null : value;
}

String _formatReleaseDate(DateTime releaseDate) {
  final month = switch (releaseDate.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
    _ => '',
  };

  return '$month ${releaseDate.day}, ${releaseDate.year}';
}
