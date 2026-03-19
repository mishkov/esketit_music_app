import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/unknown_auth_app_error.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { restoring, authenticated, unauthenticated }

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final ErrorReporter _errorReporter;

  AuthBloc({
    required AuthRepository authRepository,
    required ErrorReporter errorReporter,
  }) : _authRepository = authRepository,
       _errorReporter = errorReporter,
       super(const AuthState.initial()) {
    on<AuthSessionRestoreRequested>(_onRestoreRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onRestoreRequested(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.restoring,
        isSubmitting: false,
        failure: NullableOption.nullable(),
      ),
    );

    try {
      final session = await _authRepository.restoreSession();
      if (session == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            session: NullableOption.nullable(),
            failure: NullableOption.nullable(),
          ),
        );
        await _errorReporter.setUserId(null);
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: NullableOption.value(session),
          failure: NullableOption.nullable(),
        ),
      );
      await _errorReporter.setUserId(session.user.id.toString());
    } catch (error, stackTrace) {
      await _handleAuthFailure(
        emit,
        message: 'Failed to restore session',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      final session = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: NullableOption.value(session),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _errorReporter.setUserId(session.user.id.toString());
    } catch (error, stackTrace) {
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
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      final session = await _authRepository.signUp(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: NullableOption.value(session),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _errorReporter.setUserId(session.user.id.toString());
    } catch (error, stackTrace) {
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
    emit(
      state.copyWith(isSubmitting: true, failure: NullableOption.nullable()),
    );

    try {
      await _authRepository.signOut();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          session: NullableOption.nullable(),
          isSubmitting: false,
          failure: NullableOption.nullable(),
        ),
      );
      await _errorReporter.setUserId(null);
    } catch (error, stackTrace) {
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
  }) async {
    final failure = _toFailure(error, stackTrace);

    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        session: NullableOption.nullable(),
        isSubmitting: false,
        failure: NullableOption.value(failure),
      ),
    );
    await _errorReporter.setUserId(null);
    await _errorReporter.reportError(
      AppError(message, cause: error, stackTrace: stackTrace),
    );
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
