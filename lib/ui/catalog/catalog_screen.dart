import 'dart:async';

import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/browse_catalog_view.dart';
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
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return BlocBuilder<CatalogBloc, CatalogState>(
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
