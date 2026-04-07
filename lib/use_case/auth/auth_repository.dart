import 'package:esketit_music_app/domain/auth/auth_session.dart';

abstract interface class AuthSessionRefresher {
  Future<AuthSession?> refreshSession({bool forceRefresh = false});
}

final class DelegatingAuthSessionRefresher implements AuthSessionRefresher {
  DelegatingAuthSessionRefresher({AuthSessionRefresher? delegate})
    : _delegate = delegate;

  AuthSessionRefresher? _delegate;

  void setDelegate(AuthSessionRefresher delegate) {
    _delegate = delegate;
  }

  @override
  Future<AuthSession?> refreshSession({bool forceRefresh = false}) {
    final delegate = _delegate;
    if (delegate == null) {
      throw StateError('AuthSessionRefresher delegate is not set.');
    }

    return delegate.refreshSession(forceRefresh: forceRefresh);
  }
}

abstract class AuthRepository implements AuthSessionRefresher {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({required String email, required String password});

  Future<void> signOut();
}
