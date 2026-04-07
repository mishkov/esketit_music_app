import 'dart:async';

import 'package:esketit_music_app/ui/catalog/browse_catalog_view.dart';
import 'package:esketit_music_app/ui/catalog/search_catalog_view.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    final catalogBloc = context.read<CatalogBloc>();
    _searchController.text = catalogBloc.state.searchQuery;
    _scrollController.addListener(_onScroll);
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
                          ? BrowseCatalogView(
                              selectedTrackExists: selectedTrackExists,
                            )
                          : SearchCatalogView(
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

    // TODO: bloc have built-in support for debounce with evenet transformer.
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
