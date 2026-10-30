import 'dart:convert';

import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/agent/agent_repository.dart';

class EsketitRestApiAgentRepository implements AgentRepository {
  const EsketitRestApiAgentRepository({required HttpClient httpClient})
    : _httpClient = httpClient;

  final HttpClient _httpClient;

  @override
  Future<bool> canUseAgent() async {
    final response = await _httpClient.get('/agent/capabilities');
    if (response.statusCode == 404) return false;

    return _map(_decode(response))['canUseAgent'] == true;
  }

  @override
  Future<List<AgentConversation>> listConversations() async {
    final value = _decode(await _httpClient.get('/agent/chats'));

    return (value as List<Object?>).map(_conversation).toList(growable: false);
  }

  @override
  Future<AgentConversation> getConversation(String identifier) async =>
      _conversation(
        _decode(
          await _httpClient.get(
            '/agent/chats/${Uri.encodeComponent(identifier)}',
          ),
        ),
      );

  @override
  Future<AgentConversation> createConversation({
    required String identifier,
    required String text,
    required List<AgentAttachment> attachments,
    required String languageCode,
  }) async => _conversation(
    _decode(
      await _httpClient.post(
        '/agent/chats',
        body: {
          'id': identifier,
          'text': text,
          'locale': languageCode,
          'attachments': attachments
              .map(
                (item) => {
                  'type': _itemTypeValue(item.type),
                  'id': item.id,
                  'label': item.label,
                },
              )
              .toList(growable: false),
        },
      ),
    ),
  );

  @override
  Future<AgentConversation> sendMessage({
    required String conversationIdentifier,
    required String messageIdentifier,
    required String text,
  }) async => _conversation(
    _decode(
      await _httpClient.post(
        '/agent/chats/${Uri.encodeComponent(conversationIdentifier)}/messages',
        body: {'id': messageIdentifier, 'text': text},
      ),
    ),
  );

  @override
  Future<AgentConversation> answerQuestion({
    required String conversationIdentifier,
    required String questionIdentifier,
    required String answer,
  }) async => _conversation(
    _decode(
      await _httpClient.post(
        '/agent/chats/${Uri.encodeComponent(conversationIdentifier)}/questions/${Uri.encodeComponent(questionIdentifier)}/answer',
        body: {'answer': answer},
      ),
    ),
  );

  Future<AgentConversation> _action(String identifier, String action) async =>
      _conversation(
        _decode(
          await _httpClient.post(
            '/agent/chats/${Uri.encodeComponent(identifier)}/actions/$action',
          ),
        ),
      );

  @override
  Future<AgentConversation> stop(String identifier) =>
      _action(identifier, 'stop');

  @override
  Future<AgentConversation> resume(String identifier) =>
      _action(identifier, 'resume');

  @override
  Future<AgentConversation> cancel(String identifier) =>
      _action(identifier, 'cancel');

  @override
  Future<void> registerNotificationDevice(
    String token,
    String languageCode,
  ) async {
    _decode(
      await _httpClient.put(
        '/agent/device',
        body: {'token': token, 'locale': languageCode},
      ),
    );
  }

  @override
  Future<void> removeNotificationDevice(String token) async {
    _decode(
      await _httpClient.delete(
        '/agent/device',
        headers: {'X-Agent-Device-Token': token},
      ),
    );
  }

  Object? _decode(HttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpAppError(
        message: 'Agent request failed',
        path: '/agent',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 204) return null;

    return response.response is String
        ? jsonDecode(response.response as String)
        : response.response;
  }

  Map<String, Object?> _map(Object? value) =>
      (value as Map).cast<String, Object?>();

  List<Map<String, Object?>> _maps(Object? value) =>
      (value as List<Object?>? ?? const []).map(_map).toList(growable: false);

  AgentConversation _conversation(Object? value) {
    final data = _map(value);

    return AgentConversation(
      id: data['id'] as String,
      title: data['title'] as String,
      status: _status(data['status'] as String),
      attachments: _maps(
        data['attachments'],
      ).map(_attachment).toList(growable: false),
      messages: _maps(data['messages'])
          .map(
            (message) => AgentMessage(
              id: message['id'] as String,
              text: message['text'] as String,
              role: switch (message['role']) {
                'user' => AgentMessageRole.user,
                'assistant' => AgentMessageRole.assistant,
                _ => AgentMessageRole.system,
              },
              event: switch (message['event']) {
                'review_updated' => AgentMessageEvent.reviewUpdated,
                'operation_failed' => AgentMessageEvent.operationFailed,
                _ => null,
              },
            ),
          )
          .toList(growable: false),
      questions: _maps(data['questions'])
          .map(
            (question) => AgentQuestion(
              id: question['id'] as String,
              text: question['text'] as String,
              options: (question['options'] as List<Object?>).cast<String>(),
              answer: question['answer'] as String?,
            ),
          )
          .toList(growable: false),
      submissions: _maps(data['submissions'])
          .map(
            (submission) => AgentSubmission(
              id: (submission['submissionId'] as num).toInt(),
              status: switch (submission['status']) {
                'pending_review' => AgentReviewStatus.pending,
                'changes_requested' => AgentReviewStatus.changesRequested,
                'approved' => AgentReviewStatus.approved,
                'rejected' => AgentReviewStatus.rejected,
                _ => AgentReviewStatus.cancelled,
              },
              item: _submissionAttachment(submission),
            ),
          )
          .toList(growable: false),
      blockingConversationIds: (data['blockedBy'] as List<Object?>? ?? const [])
          .cast<String>(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['updatedAt'] as num).toInt() * 1000,
        isUtc: true,
      ),
    );
  }

  AgentAttachment? _submissionAttachment(Map<String, Object?> data) {
    final resource = data['item'];
    final item = resource is Map ? _map(resource) : data;
    final identifier = item['id'] ?? item['entityId'];
    final type = item['type'] ?? item['entityType'];
    if (identifier is! num ||
        !const ['track', 'album', 'author'].contains(type)) {
      return null;
    }

    return _attachment({'id': identifier, 'type': type, 'label': ''});
  }

  AgentAttachment _attachment(Map<String, Object?> data) => AgentAttachment(
    id: (data['id'] as num).toInt(),
    label: data['label'] as String? ?? '',
    type: switch (data['type']) {
      'track' => AgentItemType.track,
      'album' => AgentItemType.album,
      'author' => AgentItemType.author,
      _ => throw const FormatException('Unknown agent attachment type'),
    },
  );

  String _itemTypeValue(AgentItemType type) => switch (type) {
    AgentItemType.track => 'track',
    AgentItemType.album => 'album',
    AgentItemType.author => 'author',
  };

  AgentConversationStatus _status(String value) => switch (value) {
    'queued' => AgentConversationStatus.queued,
    'running' => AgentConversationStatus.working,
    'waiting_dependency' => AgentConversationStatus.waitingForItem,
    'awaiting_answer' => AgentConversationStatus.waitingForAnswer,
    'waiting_review' => AgentConversationStatus.waitingForReview,
    'stopping' => AgentConversationStatus.stopping,
    'paused' => AgentConversationStatus.paused,
    'completed' => AgentConversationStatus.completed,
    'cancelled' => AgentConversationStatus.cancelled,
    _ => AgentConversationStatus.failed,
  };
}
