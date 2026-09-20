import 'dart:io';

import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_support.dart';

void main() {
  test(
    'temporary read failure offers recovery and retry restores authentication',
    () async {
      final storage = MemoryAuthSessionStorage(testAuthSession())
        ..readError = StateError('locked');
      final reporter = RecordingAuthErrorReporter();
      final repository = testAuthRepository(
        AuthTestHttpClient(),
        storage,
        reporter,
      );
      final bloc = AuthBloc(
        authRepository: repository,
        errorReporter: reporter,
      );
      addTearDown(() async {
        await bloc.close();
        await repository.close();
      });
      final failure = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.restorationFailed,
      );
      bloc.add(const AuthSessionRestoreRequested());
      expect((await failure).failure, isNotNull);
      storage.readError = null;
      await Future<void>.delayed(Duration.zero);
      final restored = bloc.stream.firstWhere((state) => state.isAuthenticated);
      bloc.add(const AuthSessionRestoreRequested());

      expect((await restored).session, storage.session);
      expect(storage.clears, 0);
    },
  );

  test('network failure does not turn a saved session into a guest', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession(expired: true));
    final reporter = RecordingAuthErrorReporter();
    final server = AuthTestHttpClient()
      ..onPost = (_, _) async => throw const SocketException('offline');
    final repository = testAuthRepository(server, storage, reporter);
    final bloc = AuthBloc(authRepository: repository, errorReporter: reporter);
    addTearDown(() async {
      await bloc.close();
      await repository.close();
    });
    final restored = bloc.stream.firstWhere((state) => state.isAuthenticated);
    bloc.add(const AuthSessionRestoreRequested());

    expect((await restored).session, storage.session);
    expect(storage.clears, 0);
  });

  test('signing out after a read failure clears the saved session', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession())
      ..readError = const FormatException('invalid saved session');
    final reporter = RecordingAuthErrorReporter();
    final repository = testAuthRepository(
      AuthTestHttpClient(),
      storage,
      reporter,
    );
    final bloc = AuthBloc(authRepository: repository, errorReporter: reporter);
    addTearDown(() async {
      await bloc.close();
      await repository.close();
    });
    final restorationFailed = bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.restorationFailed,
    );
    bloc.add(const AuthSessionRestoreRequested());
    await restorationFailed;
    final signedOut = bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );

    bloc.add(const AuthSignOutRequested());

    expect((await signedOut).session, isNull);
    expect(storage.session, isNull);
    expect(storage.clears, 1);
  });

  test(
    'background refresh rejection updates the visible authentication state',
    () async {
      final storage = MemoryAuthSessionStorage(testAuthSession());
      final reporter = RecordingAuthErrorReporter();
      final server = AuthTestHttpClient();
      final repository = testAuthRepository(server, storage, reporter);
      final bloc = AuthBloc(
        authRepository: repository,
        errorReporter: reporter,
      );
      addTearDown(() async {
        await bloc.close();
        await repository.close();
      });
      final restored = bloc.stream.firstWhere((state) => state.isAuthenticated);
      bloc.add(const AuthSessionRestoreRequested());
      await restored;
      server.currentRefreshToken = 'revoked';
      final invalidated = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.unauthenticated,
      );
      await repository.refreshSession(forceRefresh: true);

      expect((await invalidated).session, isNull);
    },
  );
}
