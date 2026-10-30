import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/esketit_rest_api/agent/esketit_rest_api_agent_repository.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_support.dart';

void main() {
  test('older servers hide Agent instead of exposing a broken tab', () async {
    final client = AuthTestHttpClient()
      ..onGet = (_, _) async =>
          const HttpResponse(statusCode: 404, response: '');
    expect(
      await EsketitRestApiAgentRepository(httpClient: client).canUseAgent(),
      isFalse,
    );
  });

  test('maps persisted questions, dependencies and proposal targets', () async {
    final client = AuthTestHttpClient()
      ..onGet = (_, _) async => const HttpResponse(
        statusCode: 200,
        response: {
          'id': 'chat',
          'title': 'Add lyrics',
          'status': 'waiting_dependency',
          'updatedAt': 100,
          'attachments': [
            {'type': 'track', 'id': 42, 'label': 'Example'},
          ],
          'messages': [
            {
              'id': 'm',
              'role': 'system',
              'text': '',
              'event': 'review_updated',
            },
          ],
          'questions': [
            {
              'id': 'q',
              'text': 'Which version?',
              'options': ['Original', 'Deluxe'],
              'answer': null,
            },
          ],
          'submissions': [
            {
              'submissionId': 8,
              'status': 'approved',
              'entityType': 'track_lyrics',
              'entityId': 99,
              'item': {'type': 'track', 'id': 42},
            },
          ],
          'blockedBy': ['earlier-chat'],
        },
      );
    final conversation = await EsketitRestApiAgentRepository(
      httpClient: client,
    ).getConversation('chat');
    expect(conversation.status, AgentConversationStatus.waitingForItem);
    expect(conversation.pendingQuestion?.options, ['Original', 'Deluxe']);
    expect(conversation.blockingConversationIds, ['earlier-chat']);
    expect(conversation.submissions.single.item?.id, 42);
    expect(conversation.messages.single.event, AgentMessageEvent.reviewUpdated);
  });
}
