import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class AgentMessageCard extends StatelessWidget {
  const AgentMessageCard({required this.message, super.key});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.role == AgentMessageRole.user;
    final text = switch (message.event) {
      AgentMessageEvent.reviewUpdated => context.l10n.agentReviewUpdated,
      AgentMessageEvent.operationFailed => context.l10n.agentOperationFailed,
      null => message.text,
    };

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Card(
          color: fromUser
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(text),
          ),
        ),
      ),
    );
  }
}
