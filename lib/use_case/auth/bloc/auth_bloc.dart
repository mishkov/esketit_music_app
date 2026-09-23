import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/errors/auth_diagnostics.dart';
import 'package:esketit_music_app/errors/unknown_auth_app_error.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:bloc/bloc.dart';

enum AuthStatus { restoring, restorationFailed, authenticated, unauthenticated }

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested({this.showProgress = true});

  final bool showProgress;

  @override
  List<Object?> get props => [showProgress];
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged(this.session);

  final AuthSession? session;

  @override
  List<Object?> get props => [session];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AuthDiagnostics _diagnostics;
  StreamSubscription<AuthSession?>? _sessionSubscription;
  bool _isRestoring = false;
  int _operationRevision = 0;

  AuthBloc({
    required AuthRepository authRepository,
    required ErrorReporter errorReporter,
  }) : _authRepository = authRepository,
       _diagnostics = AuthDiagnostics(errorReporter),
       super(const AuthState.initial()) {
    on<AuthSessionRestoreRequested>(_onRestoreRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthSessionChanged>(_onSessionChanged);
    _sessionSubscription = _authRepository.sessionChanges.listen((session) {
      if (!isClosed) add(AuthSessionChanged(session));
    });
  }

  Future<void> _onRestoreRequested(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_isRestoring || state.isSubmitting) return;
    _isRestoring = true;
    final revision = _operationRevision;
    if (event.showProgress && state.session == null) {
      emit(
        state.copyWith(
          status: AuthStatus.restoring,
          failure: NullableOption.nullable(),
        ),
      );
    }
    await _diagnostics.record('Authentication restoration requested', {
      'trigger': event.showProgress ? 'startup_or_retry' : 'foreground',
      'previousStatus': state.status.name,
    });
    try {
      final session = await _authRepository.restoreSession();
      if (revision != _operationRevision) return;
      emit(
        state.copyWith(
          status: session == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          session: session == null
              ? NullableOption.nullable()
              : NullableOption.value(session),
          failure: NullableOption.nullable(),
        ),
      );
      await _diagnostics.setUserId(session?.user.id.toString());
    } catch (error, stackTrace) {
      if (revision != _operationRevision) return;
      await _handleAuthFailure(
        emit,
        message: 'Failed to restore session',
        error: error,
        stackTrace: stackTrace,
        restoring: true,
      );
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> _onSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    final previousStatus = state.status;
    emit(
      state.copyWith(
        status: event.session == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        session: event.session == null
            ? NullableOption.nullable()
            : NullableOption.value(event.session!),
        failure: NullableOption.nullable(),
      ),
    );
    await _diagnostics.record('Authentication state synchronized', {
      'previousStatus': previousStatus.name,
      'status': state.status.name,
    });
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final revision = ++_operationRevision;
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      final session = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      if (revision != _operationRevision) return;
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: NullableOption.value(session),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _diagnostics.setUserId(session.user.id.toString());
    } catch (error, stackTrace) {
      if (revision != _operationRevision) return;
      await _handleAuthFailure(
        emit,
        message: 'Failed to sign in',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final revision = ++_operationRevision;
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      final session = await _authRepository.signUp(
        email: event.email,
        password: event.password,
      );
      if (revision != _operationRevision) return;
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: NullableOption.value(session),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _diagnostics.setUserId(session.user.id.toString());
    } catch (error, stackTrace) {
      if (revision != _operationRevision) return;
      await _handleAuthFailure(
        emit,
        message: 'Failed to sign up',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final revision = ++_operationRevision;
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      await _authRepository.signOut();
      if (revision != _operationRevision) return;
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          session: NullableOption.nullable(),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _diagnostics.setUserId(null);
    } catch (error, stackTrace) {
      if (revision != _operationRevision) return;
      await _handleAuthFailure(
        emit,
        message: 'Failed to sign out',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleAuthFailure(
    Emitter<AuthState> emit, {
    required String message,
    required Object error,
    required StackTrace stackTrace,
    bool restoring = false,
  }) async {
    final failure = _toFailure(error, stackTrace);
    final previousSession = state.session;
    emit(
      state.copyWith(
        status: previousSession != null
            ? AuthStatus.authenticated
            : restoring
            ? AuthStatus.restorationFailed
            : AuthStatus.unauthenticated,
        isSubmitting: false,
        failure: NullableOption.value(failure),
      ),
    );
    if (error is! AuthAppError) {
      await _diagnostics.failure(
        operation: restoring ? 'restore' : 'user_action',
        message: message,
        error: error,
        stackTrace: stackTrace,
        data: {'status': state.status.name},
      );
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await super.close();
  }

  AppError _toFailure(Object error, StackTrace stackTrace) {
    if (error is AppError) {
      return error;
    }

    return UnknownAuthAppError(cause: error, stackTrace: stackTrace);
  }
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthSession? session;
  final bool isSubmitting;
  final AppError? failure;

  const AuthState({
    required this.status,
    required this.isSubmitting,
    this.session,
    this.failure,
  });

  const AuthState.initial()
    : this(status: AuthStatus.restoring, isSubmitting: false);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    NullableOption<AuthSession>? session,
    bool? isSubmitting,
    NullableOption<AppError>? failure,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session == null ? this.session : session.value,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: failure == null ? this.failure : failure.value,
    );
  }

  @override
  List<Object?> get props => [status, session, isSubmitting, failure];
}
