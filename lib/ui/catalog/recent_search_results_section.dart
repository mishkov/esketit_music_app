import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_search_result_tile.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentSearchResultsSection extends StatelessWidget {
  const RecentSearchResultsSection({
    required this.results,
    required this.selectedTrackExists,
    super.key,
  });

  final List<CatalogSearchResultItem> results;
  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.l10n.recentSearchResultsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              selectedTrackExists ? 100 : 16,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];

              return CatalogSearchResultTile(
                result: result,
                onTap: () => context.read<CatalogBloc>().add(
                  SearchResultClicked(result: result, resultRank: index + 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
