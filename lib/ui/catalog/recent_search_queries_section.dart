import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class RecentSearchQueriesSection extends StatelessWidget {
  const RecentSearchQueriesSection({
    required this.recentSearchQueries,
    required this.onQuerySelected,
    required this.selectedTrackExists,
    super.key,
  });

  final List<String> recentSearchQueries;
  final ValueChanged<String> onQuerySelected;
  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    if (recentSearchQueries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.l10n.recentSearchQueriesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: selectedTrackExists ? 100 : 16),
            itemCount: recentSearchQueries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final query = recentSearchQueries[index];

              return ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(query),
                trailing: const Icon(Icons.north_west_rounded),
                onTap: () => onQuerySelected(query),
              );
            },
          ),
        ),
      ],
    );
  }
}
