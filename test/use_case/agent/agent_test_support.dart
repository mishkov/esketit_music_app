import 'dart:async';

import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/use_case/agent/agent_notifications.dart';
import 'package:esketit_music_app/use_case/agent/agent_repository.dart';

AgentConversation testConversation({
  String identifier = 'chat',
  AgentConversationStatus status = AgentConversationStatus.working,
}) => AgentConversation(
  id: identifier,
  title: 'Example request',
  status: status,
  attachments: const [],
  messages: const [],
  questions: const [],
  submissions: const [],
  blockingConversationIds: const [],
  updatedAt: DateTime.utc(2026),
);

class FakeAgentRepository implements AgentRepository {
  Future<bool> Function()? onAccess;
  Future<AgentConversation> Function(String)? onGet;
  Future<AgentConversation> Function(String, String)? onCreate;
  final createdIdentifiers = <String>[];
  final sentIdentifiers = <String>[];
  AgentConversation conversation = testConversation();
  final devices = <String>[];

  @override
  Future<bool> canUseAgent() async => onAccess == null ? true : onAccess!();
  @override
  Future<List<AgentConversation>> listConversations() async => [conversation];
  @override
  Future<AgentConversation> getConversation(String identifier) async =>
      onGet == null ? conversation : onGet!(identifier);
  @override
  Future<AgentConversation> createConversation({
    required String identifier,
    required String text,
    required List<AgentAttachment> attachments,
    required String languageCode,
  }) async {
    createdIdentifiers.add(identifier);

    return onCreate == null
        ? testConversation(identifier: identifier)
        : onCreate!(identifier, text);
  }

  @override
  Future<AgentConversation> sendMessage({
    required String conversationIdentifier,
    required String messageIdentifier,
    required String text,
  }) async {
    sentIdentifiers.add(messageIdentifier);

    return conversation;
  }

  @override
  Future<AgentConversation> answerQuestion({
    required String conversationIdentifier,
    required String questionIdentifier,
    required String answer,
  }) async => conversation;
  @override
  Future<AgentConversation> stop(String identifier) async => testConversation(
    identifier: identifier,
    status: AgentConversationStatus.paused,
  );
  @override
  Future<AgentConversation> resume(String identifier) async =>
      testConversation(identifier: identifier);
  @override
  Future<AgentConversation> cancel(String identifier) async => testConversation(
    identifier: identifier,
    status: AgentConversationStatus.cancelled,
  );
  @override
  Future<void> registerNotificationDevice(
    String token,
    String languageCode,
  ) async => devices.add(token);
  @override
  Future<void> removeNotificationDevice(String token) async =>
      devices.remove(token);
}

class FakeAgentNotifications implements AgentNotifications {
  final opened = StreamController<String>.broadcast();
  final tokens = StreamController<String>.broadcast();
  int resets = 0;
  @override
  bool get isConfigured => false;
  @override
  Stream<String> get openedConversations => opened.stream;
  @override
  Stream<String> get refreshedTokens => tokens.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> enable() async => null;
  @override
  Future<void> reset() async {
    resets++;
  }

  @override
  Future<void> dispose() async {
    await opened.close();
    await tokens.close();
  }
}
