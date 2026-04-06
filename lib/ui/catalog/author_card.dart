import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AuthorCard extends StatelessWidget {
  const AuthorCard({required this.author, super.key});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAuthorDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RemoteImage(
                imageUrl: author.primaryPhotoUrl,
                icon: Icons.person_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                author.currentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAuthorDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthorDetailsScreen(author: author),
      ),
    );
  }
}
