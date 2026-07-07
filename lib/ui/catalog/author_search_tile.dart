import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AuthorSearchTile extends StatelessWidget {
  const AuthorSearchTile({required this.author, this.onTap, super.key});

  final Author author;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
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
        subtitle: Text(l10n.authorTypeLabel),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openDetails(context),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    onTap?.call();
    openAuthorDetails(context, author);
  }
}
