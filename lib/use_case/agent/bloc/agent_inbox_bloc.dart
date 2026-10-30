import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/agent/agent_notifications.dart';
import 'package:esketit_music_app/use_case/agent/agent_repository.dart';

sealed class AgentInboxEvent {
  const AgentInboxEvent();
}

final class AgentAccountChanged extends AgentInboxEvent {
  const AgentAccountChanged(this.identifier);
  final int? identifier;
}

final class AgentInboxRefreshRequested extends AgentInboxEvent {
  const AgentInboxRefreshRequested();
}

final class AgentNotificationsRequested extends AgentInboxEvent {
  const AgentNotificationsRequested(this.languageCode);
  final String languageCode;
}

class AgentInboxState extends Equatable {
  const AgentInboxState({
    this.accountIdentifier,
    this.canUseAgent = false,
    this.isLoading = false,
    this.hasError = false,
    this.notificationsAvailable = false,
    this.conversations = const [],
  });

  final int? accountIdentifier;
  final bool canUseAgent;
  final bool isLoading;
  final bool hasError;
  final bool notificationsAvailable;
  final List<AgentConversation> conversations;

  @override
  List<Object?> get props => [
    accountIdentifier,
    canUseAgent,
    isLoading,
    hasError,
    notificationsAvailable,
    conversations,
  ];
}

class AgentInboxBloc extends Bloc<AgentInboxEvent, AgentInboxState> {
  AgentInboxBloc({
    required AgentRepository repository,
    required AgentNotifications notifications,
    required ErrorReporter errorReporter,
    Duration refreshInterval = const Duration(seconds: 5),
  }) : _repository = repository,
       _notifications = notifications,
       _errorReporter = errorReporter,
       super(const AgentInboxState()) {
    on<AgentAccountChanged>(_accountChanged);
    on<AgentInboxRefreshRequested>(_refresh);
    on<AgentNotificationsRequested>(_enableNotifications);
    _timer = Timer.periodic(refreshInterval, (_) {
      if (state.canUseAgent && !isClosed) {
        add(const AgentInboxRefreshRequested());
      }
    });
    _tokens = notifications.refreshedTokens.listen(
      _registerToken,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(_report(error, stackTrace));
      },
    );
  }

  final AgentRepository _repository;
  final AgentNotifications _notifications;
  final ErrorReporter _errorReporter;
  Timer? _timer;
  StreamSubscription<String>? _tokens;
  int _generation = 0;
  bool _refreshing = false;
  String? _deviceToken;
  String _languageCode = 'en';

  Stream<String> get openedConversations => _notifications.openedConversations;

  Future<void> _accountChanged(
    AgentAccountChanged event,
    Emitter<AgentInboxState> emit,
  ) async {
    final generation = ++_generation;
    final previousAccount = state.accountIdentifier;
    final previousToken = _deviceToken;
    _deviceToken = null;
    emit(
      AgentInboxState(
        accountIdentifier: event.identifier,
        isLoading: event.identifier != null,
      ),
    );
    if (previousAccount != null && previousAccount != event.identifier) {
      try {
        await _notifications.reset();
      } catch (error, stackTrace) {
        await _report(error, stackTrace);
      }
    }
    if (event.identifier == null) {
      // Deleting the installation token prevents notifications for the old account
      // even if the authenticated server deregistration can no longer run.
      if (previousToken != null) {
        try {
          await _repository.removeNotificationDevice(previousToken);
        } catch (_) {
          /* Token is detached on its next registration. */
        }
      }

      return;
    }
    try {
      final allowed = await _repository.canUseAgent();
      if (generation != _generation) return;
      emit(
        AgentInboxState(
          accountIdentifier: event.identifier,
          canUseAgent: allowed,
          notificationsAvailable: _notifications.isConfigured,
        ),
      );

      if (allowed) {
        try {
          await _notifications.initialize();
        } catch (error, stackTrace) {
          await _report(error, stackTrace);
        }
        if (generation == _generation) add(const AgentInboxRefreshRequested());
      }
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
      if (generation == _generation) {
        emit(
          AgentInboxState(accountIdentifier: event.identifier, hasError: true),
        );
      }
    }
  }

  Future<void> _refresh(
    AgentInboxRefreshRequested event,
    Emitter<AgentInboxState> emit,
  ) async {
    if (!state.canUseAgent || _refreshing) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final conversations = await _repository.listConversations();
      if (generation != _generation) return;
      emit(
        AgentInboxState(
          accountIdentifier: state.accountIdentifier,
          canUseAgent: true,
          notificationsAvailable: _notifications.isConfigured,
          conversations: conversations,
        ),
      );
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
      if (generation == _generation) {
        emit(
          AgentInboxState(
            accountIdentifier: state.accountIdentifier,
            canUseAgent: state.canUseAgent,
            notificationsAvailable: _notifications.isConfigured,
            conversations: state.conversations,
            hasError: true,
          ),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _enableNotifications(
    AgentNotificationsRequested event,
    Emitter<AgentInboxState> emit,
  ) async {
    if (!state.canUseAgent) return;
    _languageCode = event.languageCode;
    try {
      final token = await _notifications.enable();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
    }
  }

  Future<void> _registerToken(String token) async {
    if (!state.canUseAgent) return;
    try {
      await _repository.registerNotificationDevice(token, _languageCode);
      _deviceToken = token;
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
    }
  }

  Future<void> _report(Object error, StackTrace stackTrace) =>
      _errorReporter.reportError(
        AppError(
          'Agent inbox operation failed',
          cause: error,
          stackTrace: stackTrace,
        ),
      );

  @override
  Future<void> close() async {
    ++_generation;
    _timer?.cancel();
    await _tokens?.cancel();
    await _notifications.dispose();
    await super.close();
  }
}
