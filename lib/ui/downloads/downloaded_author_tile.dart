import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';

class DownloadedAuthorTile extends StatelessWidget {
  const DownloadedAuthorTile({
    required this.author,
    required this.trackCount,
    required this.onTap,
    super.key,
  });

  final Author author;
  final int trackCount;
  final VoidCallback onTap;

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
        subtitle: Text(context.l10n.playlistTracksCount(trackCount)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
