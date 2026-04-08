import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class EsketitBottomNavigationBar extends StatelessWidget {
  const EsketitBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          label: l10n.homeNavigationLabel,
          icon: const Icon(Icons.home_rounded),
        ),
        BottomNavigationBarItem(
          label: l10n.searchNavigationLabel,
          icon: const Icon(Icons.search_rounded),
        ),
        BottomNavigationBarItem(
          label: l10n.myLibraryNavigationLabel,
          icon: const Icon(Icons.library_music_rounded),
        ),
      ],
    );
  }
}
