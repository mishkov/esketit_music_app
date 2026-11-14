import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/agent/agent_repository.dart';
import 'package:uuid/uuid.dart';

typedef AgentConversationBlocFactory =
    AgentConversationBloc Function({
      String? identifier,
      AgentAttachment? attachment,
    });

sealed class AgentConversationEvent {
  const AgentConversationEvent();
}

final class AgentConversationRefreshRequested extends AgentConversationEvent {
  const AgentConversationRefreshRequested();
}

final class AgentMessageSent extends AgentConversationEvent {
  const AgentMessageSent(this.text, this.languageCode);
  final String text;
  final String languageCode;
}

final class AgentAnswerSent extends AgentConversationEvent {
  const AgentAnswerSent(this.questionIdentifier, this.answer);
  final String questionIdentifier;
  final String answer;
}

enum AgentControl { stop, resume, cancel }

final class AgentControlRequested extends AgentConversationEvent {
  const AgentControlRequested(this.control);
  final AgentControl control;
}

class AgentConversationState extends Equatable {
  const AgentConversationState({
    this.conversation,
    this.isLoading = false,
    this.isSubmitting = false,
    this.hasError = false,
    this.sentMessageCount = 0,
  });

  final AgentConversation? conversation;
  final bool isLoading;
  final bool isSubmitting;
  final bool hasError;
  final int sentMessageCount;

  @override
  List<Object?> get props => [
    conversation,
    isLoading,
    isSubmitting,
    hasError,
    sentMessageCount,
  ];
}

class AgentConversationBloc
    extends Bloc<AgentConversationEvent, AgentConversationState> {
  AgentConversationBloc({
    required AgentRepository repository,
    required ErrorReporter errorReporter,
    String? identifier,
    this.attachment,
    Duration refreshInterval = const Duration(seconds: 3),
  }) : _repository = repository,
       _errorReporter = errorReporter,
       identifier = identifier ?? const Uuid().v4(),
       _created = identifier != null,
       super(AgentConversationState(isLoading: identifier != null)) {
    on<AgentConversationRefreshRequested>(_refresh);
    on<AgentMessageSent>(_send);
    on<AgentAnswerSent>(_answer);
    on<AgentControlRequested>(_control);
    _timer = Timer.periodic(refreshInterval, (_) {
      if (_created && !isClosed) add(const AgentConversationRefreshRequested());
    });
    if (_created) add(const AgentConversationRefreshRequested());
  }

  final AgentRepository _repository;
  final ErrorReporter _errorReporter;
  final String identifier;
  final AgentAttachment? attachment;
  Timer? _timer;
  bool _created;
  String? _initialMessageText;
  String? _initialLanguageCode;
  bool _busy = false;
  int _revision = 0;
  String? _pendingText;
  String? _pendingMessageIdentifier;

  Future<void> _refresh(
    AgentConversationRefreshRequested event,
    Emitter<AgentConversationState> emit,
  ) async {
    if (!_created || _busy) return;
    final revision = _revision;
    try {
      final conversation = await _repository.getConversation(identifier);
      if (revision != _revision || _busy) return;
      emit(
        AgentConversationState(
          conversation: conversation,
          sentMessageCount: state.sentMessageCount,
        ),
      );
    } catch (error, stackTrace) {
      if (revision == _revision) await _failure(error, stackTrace, emit);
    }
  }

  Future<void> _send(
    AgentMessageSent event,
    Emitter<AgentConversationState> emit,
  ) async {
    if (_busy || event.text.trim().isEmpty) return;
    await _mutate(emit, () async {
      if (!_created) {
        _initialMessageText ??= event.text.trim();
        _initialLanguageCode ??= event.languageCode;
        final conversation = await _repository.createConversation(
          identifier: identifier,
          text: _initialMessageText!,
          attachments: [?attachment],
          languageCode: _initialLanguageCode!,
        );
        _created = true;
        if (event.text.trim() == _initialMessageText) return conversation;
      }
      if (_pendingText != event.text.trim()) {
        _pendingText = event.text.trim();
        _pendingMessageIdentifier = const Uuid().v4();
      }
      final conversation = await _repository.sendMessage(
        conversationIdentifier: identifier,
        messageIdentifier: _pendingMessageIdentifier!,
        text: event.text.trim(),
      );
      _pendingText = null;
      _pendingMessageIdentifier = null;

      return conversation;
    }, messageSent: true);
  }

  Future<void> _answer(
    AgentAnswerSent event,
    Emitter<AgentConversationState> emit,
  ) => _mutate(
    emit,
    () => _repository.answerQuestion(
      conversationIdentifier: identifier,
      questionIdentifier: event.questionIdentifier,
      answer: event.answer,
    ),
    messageSent: true,
  );

  Future<void> _control(
    AgentControlRequested event,
    Emitter<AgentConversationState> emit,
  ) => _mutate(
    emit,
    () => switch (event.control) {
      AgentControl.stop => _repository.stop(identifier),
      AgentControl.resume => _repository.resume(identifier),
      AgentControl.cancel => _repository.cancel(identifier),
    },
  );

  Future<void> _mutate(
    Emitter<AgentConversationState> emit,
    Future<AgentConversation> Function() operation, {
    bool messageSent = false,
  }) async {
    if (_busy) return;
    _busy = true;
    ++_revision;
    emit(
      AgentConversationState(
        conversation: state.conversation,
        isSubmitting: true,
        sentMessageCount: state.sentMessageCount,
      ),
    );
    try {
      final conversation = await operation();
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Agent conversation updated',
          data: {
            'conversationId': identifier,
            'status': conversation.status.name,
          },
        ),
      );
      emit(
        AgentConversationState(
          conversation: conversation,
          sentMessageCount: state.sentMessageCount + (messageSent ? 1 : 0),
        ),
      );
    } catch (error, stackTrace) {
      await _failure(error, stackTrace, emit);
    } finally {
      _busy = false;
    }
  }

  Future<void> _failure(
    Object error,
    StackTrace stackTrace,
    Emitter<AgentConversationState> emit,
  ) async {
    await _errorReporter.reportError(
      AppError(
        'Agent conversation operation failed',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
    emit(
      AgentConversationState(
        conversation: state.conversation,
        hasError: true,
        sentMessageCount: state.sentMessageCount,
      ),
    );
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    ++_revision;
    await super.close();
  }
}
