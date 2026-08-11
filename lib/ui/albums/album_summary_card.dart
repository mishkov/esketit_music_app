import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class AlbumSummaryCard extends StatelessWidget {
  const AlbumSummaryCard({required this.album, this.downloadAction, super.key});

  final Album album;
  final Widget? downloadAction;

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
                  file: album.coverImage,
                  icon: Icons.album_rounded,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              album.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (downloadAction != null) ...[
              const SizedBox(height: 12),
              downloadAction!,
            ],
          ],
        ),
      ),
    );
  }
}
