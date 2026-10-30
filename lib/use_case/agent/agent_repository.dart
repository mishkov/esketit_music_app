import 'package:esketit_music_app/domain/agent/agent_conversation.dart';

abstract interface class AgentRepository {
  Future<bool> canUseAgent();
  Future<List<AgentConversation>> listConversations();
  Future<AgentConversation> getConversation(String identifier);
  Future<AgentConversation> createConversation({
    required String identifier,
    required String text,
    required List<AgentAttachment> attachments,
    required String languageCode,
  });
  Future<AgentConversation> sendMessage({
    required String conversationIdentifier,
    required String messageIdentifier,
    required String text,
  });
  Future<AgentConversation> answerQuestion({
    required String conversationIdentifier,
    required String questionIdentifier,
    required String answer,
  });
  Future<AgentConversation> stop(String identifier);
  Future<AgentConversation> resume(String identifier);
  Future<AgentConversation> cancel(String identifier);
  Future<void> registerNotificationDevice(String token, String languageCode);
  Future<void> removeNotificationDevice(String token);
}
