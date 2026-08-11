import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class DownloadedLibraryCategoryTile extends StatelessWidget {
  const DownloadedLibraryCategoryTile({
    required this.title,
    required this.icon,
    required this.itemCount,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(context.l10n.downloadedItemsCount(itemCount)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
