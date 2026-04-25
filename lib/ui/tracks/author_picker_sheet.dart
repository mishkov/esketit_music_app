import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

Future<void> openAuthorSelection(
  BuildContext context,
  List<Author> authors,
) async {
  if (authors.isEmpty) {
    return;
  }
  if (authors.length == 1) {
    openAuthorDetails(context, authors.first);

    return;
  }

  final selectedAuthor = await showModalBottomSheet<Author>(
    context: context,
    showDragHandle: true,
    builder: (context) => AuthorPickerSheet(authors: authors),
  );

  if (selectedAuthor == null || !context.mounted) {
    return;
  }

  openAuthorDetails(context, selectedAuthor);
}

class AuthorPickerSheet extends StatelessWidget {
  const AuthorPickerSheet({required this.authors, super.key});

  final List<Author> authors;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.trackScreenChooseAuthorTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: authors.length,
                itemBuilder: (context, index) {
                  final author = authors[index];

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
                      subtitle: Text(context.l10n.authorTypeLabel),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).pop(author),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
