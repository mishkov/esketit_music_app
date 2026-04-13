import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AuthorSummaryCard extends StatelessWidget {
  const AuthorSummaryCard({required this.author, super.key});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: RemoteImage(
                  imageUrl: author.primaryPhotoUrl,
                  icon: Icons.person_rounded,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              author.currentName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
