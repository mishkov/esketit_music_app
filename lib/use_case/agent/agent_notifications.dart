abstract interface class AgentNotifications {
  bool get isConfigured;
  Stream<String> get openedConversations;
  Stream<String> get refreshedTokens;
  Future<String?> enable();
  Future<void> initialize();
  Future<void> reset();
  Future<void> dispose();
}
