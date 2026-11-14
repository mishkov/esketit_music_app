import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/agent/agent_routes.dart';
import 'package:esketit_music_app/ui/agent/agent_access_scope.dart';
import 'package:flutter/material.dart';

class AskAgentAction extends StatelessWidget {
  const AskAgentAction({required this.attachment, super.key});

  final AgentAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return AgentAccessScope.of(context)
        ? IconButton(
            tooltip: context.l10n.askAgent,
            onPressed: () => openAgentDraft(context, attachment: attachment),
            icon: const Icon(Icons.auto_awesome_outlined),
          )
        : const SizedBox.shrink();
  }
}
