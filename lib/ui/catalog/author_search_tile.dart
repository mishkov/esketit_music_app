import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AuthorSearchTile extends StatelessWidget {
  const AuthorSearchTile({required this.author, super.key});

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
        onTap: () => openAuthorDetails(context, author),
      ),
    );
  }
}
