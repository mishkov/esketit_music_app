import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/browse_catalog_view.dart';
import 'package:esketit_music_app/ui/catalog/recent_search_queries_section.dart';
import 'package:esketit_music_app/ui/catalog/search_catalog_view.dart';
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
  static const double _lazyLoadTriggerOffset = 240;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final catalogBloc = context.read<CatalogBloc>();
    _searchController.text = catalogBloc.state.searchQuery;
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            final activeQuery = state.searchQuery.trim();
            final showRecentSearchQueries =
                _searchFocusNode.hasFocus &&
                activeQuery.isEmpty &&
                state.recentSearchQueries.isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: activeQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.clearSearchTooltip,
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: showRecentSearchQueries
                      ? TextFieldTapRegion(
                          child: RecentSearchQueriesSection(
                            recentSearchQueries: state.recentSearchQueries,
                            onQuerySelected: _applyRecentSearchQuery,
                            selectedTrackExists: selectedTrackExists,
                          ),
                        )
                      : activeQuery.isEmpty
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
        );
      },
    );
  }

  void _onSearchQueryChanged(String value) {
    final catalogBloc = context.read<CatalogBloc>();
    catalogBloc.add(
      CatalogSearchQueryChanged(
        value,
        loadSearchResults: value.trim().isNotEmpty,
        debounceSearchResultsLoading: true,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchQueryChanged('');
  }

  void _applyRecentSearchQuery(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    context.read<CatalogBloc>().add(
      CatalogSearchQueryChanged(query, loadSearchResults: true),
    );
  }

  void _onSearchFocusChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
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
}
