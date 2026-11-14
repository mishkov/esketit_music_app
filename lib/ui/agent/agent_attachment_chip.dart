import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/agent/agent_localization.dart';
import 'package:esketit_music_app/ui/albums/album_routes.dart';
import 'package:esketit_music_app/ui/authors/author_routes.dart';
import 'package:esketit_music_app/ui/tracks/track_routes.dart';
import 'package:flutter/material.dart';

class AgentAttachmentChip extends StatelessWidget {
  const AgentAttachmentChip({required this.attachment, super.key});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '@${attachment.type.name}-${attachment.id}',
      child: ActionChip(
        avatar: Icon(switch (attachment.type) {
          AgentItemType.track => Icons.music_note_rounded,
          AgentItemType.album => Icons.album_outlined,
          AgentItemType.author => Icons.person_outline_rounded,
        }),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            attachment.label.isEmpty
                ? agentItemLabel(context.l10n, attachment.type)
                : attachment.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onPressed: () => _open(context),
      ),
    );
  }

  void _open(BuildContext context) =>
      Navigator.of(context).pushNamed(switch (attachment.type) {
        AgentItemType.track => trackRoutePath(attachment.id),
        AgentItemType.album => albumRoutePath(attachment.id),
        AgentItemType.author => authorRoutePath(attachment.id),
      });
}
