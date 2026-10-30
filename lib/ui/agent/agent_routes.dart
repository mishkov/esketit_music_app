import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:flutter/widgets.dart';

const agentNewChatRoute = '/agent/new';

String agentConversationRoute(String identifier) =>
    '/agent/chats/${Uri.encodeComponent(identifier)}';

void openAgentDraft(BuildContext context, {AgentAttachment? attachment}) {
  Navigator.of(context).pushNamed(agentNewChatRoute, arguments: attachment);
}

void openAgentConversation(BuildContext context, String identifier) {
  Navigator.of(context).pushNamed(agentConversationRoute(identifier));
}
