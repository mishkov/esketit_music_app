import 'dart:async';

import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_conversation_bloc.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_inbox_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_support.dart';
import 'agent_test_support.dart';

void main() {
  test('opening a draft does not create work', () async {
    final repository = FakeAgentRepository();
    final bloc = AgentConversationBloc(
      repository: repository,
      errorReporter: RecordingAuthErrorReporter(),
    );
    addTearDown(bloc.close);
    await Future<void>.delayed(Duration.zero);
    expect(repository.createdIdentifiers, isEmpty);
    expect(bloc.state.conversation, isNull);
  });

  test('creation retry preserves its identifier after a timeout', () async {
    final repository = FakeAgentRepository()
      ..onGet = (_) async => throw HttpAppError(
        message: 'Missing',
        path: '/agent',
        statusCode: 404,
      );
    var attempts = 0;
    repository.onCreate = (identifier, text) async {
      if (attempts++ == 0) throw TimeoutException('offline');

      return testConversation(identifier: identifier);
    };
    final bloc = AgentConversationBloc(
      repository: repository,
      errorReporter: RecordingAuthErrorReporter(),
    );
    addTearDown(bloc.close);
    final failed = bloc.stream.firstWhere((state) => state.hasError);
    bloc.add(const AgentMessageSent('Add lyrics', 'en'));
    await failed;
    final sent = bloc.stream.firstWhere((state) => state.sentMessageCount == 1);
    bloc.add(const AgentMessageSent('Add lyrics', 'en'));
    await sent;
    expect(repository.createdIdentifiers, hasLength(2));
    expect(repository.createdIdentifiers.toSet(), hasLength(1));
    expect(repository.sentIdentifiers, isEmpty);
  });

  test(
    'editing a timed-out draft reconciles its original request first',
    () async {
      final repository = FakeAgentRepository();
      final texts = <String>[];
      repository.onCreate = (identifier, text) async {
        texts.add(text);
        if (texts.length == 1) throw TimeoutException('response lost');

        return testConversation(identifier: identifier);
      };
      final bloc = AgentConversationBloc(
        repository: repository,
        errorReporter: RecordingAuthErrorReporter(),
      );
      addTearDown(bloc.close);
      final failed = bloc.stream.firstWhere((state) => state.hasError);
      bloc.add(const AgentMessageSent('Add lyrics', 'en'));
      await failed;
      final sent = bloc.stream.firstWhere(
        (state) => state.sentMessageCount == 1,
      );
      bloc.add(const AgentMessageSent('Use the live version instead', 'en'));
      await sent;
      expect(texts, ['Add lyrics', 'Add lyrics']);
      expect(repository.sentIdentifiers, hasLength(1));
    },
  );

  test('late polling result cannot undo Stop', () async {
    final repository = FakeAgentRepository();
    final bloc = AgentConversationBloc(
      identifier: 'chat',
      repository: repository,
      errorReporter: RecordingAuthErrorReporter(),
      refreshInterval: const Duration(hours: 1),
    );
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((state) => state.conversation != null);
    final delayed = Completer<AgentConversation>();
    repository.onGet = (_) => delayed.future;
    bloc.add(const AgentConversationRefreshRequested());
    await Future<void>.delayed(Duration.zero);
    final paused = bloc.stream.firstWhere(
      (state) => state.conversation?.status == AgentConversationStatus.paused,
    );
    bloc.add(const AgentControlRequested(AgentControl.stop));
    await paused;
    delayed.complete(testConversation());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.conversation?.status, AgentConversationStatus.paused);
  });

  test('late access response cannot restore access after sign-out', () async {
    final access = Completer<bool>();
    final repository = FakeAgentRepository()..onAccess = () => access.future;
    final bloc = AgentInboxBloc(
      repository: repository,
      notifications: FakeAgentNotifications(),
      errorReporter: RecordingAuthErrorReporter(),
    );
    addTearDown(bloc.close);
    bloc.add(const AgentAccountChanged(2));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const AgentAccountChanged(null));
    await Future<void>.delayed(Duration.zero);
    access.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.canUseAgent, isFalse);
    expect(bloc.state.conversations, isEmpty);
  });

  test('changing accounts invalidates the notification registration', () async {
    final notifications = FakeAgentNotifications();
    final bloc = AgentInboxBloc(
      repository: FakeAgentRepository(),
      notifications: notifications,
      errorReporter: RecordingAuthErrorReporter(),
    );
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere((state) => state.canUseAgent);
    bloc.add(const AgentAccountChanged(2));
    await ready;
    bloc.add(const AgentAccountChanged(null));
    await Future<void>.delayed(Duration.zero);
    expect(notifications.resets, 1);
  });
}
