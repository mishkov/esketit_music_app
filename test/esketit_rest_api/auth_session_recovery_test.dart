import 'dart:async';
import 'dart:io';

import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_test_support.dart';

void main() {
  test('restoration keeps the rotated tokens after a me retry', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession());
    final server = AuthTestHttpClient()..rejectOldAccess = true;
    final repository = testAuthRepository(
      server,
      storage,
      RecordingAuthErrorReporter(),
    );
    addTearDown(repository.close);

    final restored = await repository.restoreSession();

    expect(restored!.refreshToken, 'secret-new-refresh');
    expect(storage.session!.refreshToken, 'secret-new-refresh');
    expect(
      storage.writes.every(
        (session) => session.refreshToken == 'secret-new-refresh',
      ),
      isTrue,
    );
    expect(server.refreshRequests, 1);
  });

  test('offline restoration keeps saved identity and later recovers', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession(expired: true));
    final reporter = RecordingAuthErrorReporter();
    final server = AuthTestHttpClient()
      ..onPost = (_, _) async => throw const SocketException('offline');
    final repository = testAuthRepository(server, storage, reporter);
    addTearDown(repository.close);

    expect(await repository.restoreSession(), storage.session);
    expect(storage.clears, 0);
    expect(reporter.errors.single, isA<AuthAppError>());
    server.onPost = null;
    expect(
      (await repository.restoreSession())!.refreshToken,
      'secret-new-refresh',
    );
  });

  test('me server failure retains session and records HTTP status', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession());
    final reporter = RecordingAuthErrorReporter();
    final server = AuthTestHttpClient()
      ..onGet = (_, _) async =>
          const HttpResponse(statusCode: 503, response: 'private body');
    final repository = testAuthRepository(server, storage, reporter);
    addTearDown(repository.close);

    expect(await repository.restoreSession(), storage.session);
    expect(storage.clears, 0);
    expect((reporter.errors.single as AuthAppError).details['statusCode'], 503);
  });

  test(
    'failed rotated-token write is retried before the next request and survives restart',
    () async {
      final storage = MemoryAuthSessionStorage(testAuthSession(expired: true))
        ..writeError = StateError('storage unavailable');
      final server = AuthTestHttpClient();
      final reporter = RecordingAuthErrorReporter();
      final repository = testAuthRepository(server, storage, reporter);
      addTearDown(repository.close);

      expect(
        (await repository.refreshSession())!.refreshToken,
        'secret-new-refresh',
      );
      expect(storage.session!.refreshToken, 'secret-old-refresh');
      expect(
        (reporter.errors.single as AuthAppError).details['persistencePending'],
        isTrue,
      );
      storage.writeError = null;
      await repository.refreshSession();
      expect(storage.session!.refreshToken, 'secret-new-refresh');
      expect(server.refreshRequests, 1);
      final restarted = testAuthRepository(server, storage, reporter);
      addTearDown(restarted.close);
      expect(
        (await restarted.restoreSession())!.refreshToken,
        'secret-new-refresh',
      );
    },
  );

  test(
    'rejected refresh reports context before clearing and publishes loss of session',
    () async {
      final storage = MemoryAuthSessionStorage(testAuthSession(expired: true));
      final server = AuthTestHttpClient()..currentRefreshToken = 'different';
      final reporter = RecordingAuthErrorReporter();
      final repository = testAuthRepository(server, storage, reporter);
      addTearDown(repository.close);
      final change = repository.sessionChanges.first;

      expect(await repository.refreshSession(), isNull);
      expect(await change, isNull);
      expect(storage.session, isNull);
      final failure = reporter.errors.single as AuthAppError;
      expect(failure.operation, 'invalidate');
      expect(failure.details, isNot(contains('userId')));
      expect(failure.details['clearReason'], 'refresh_rejected');
      expect(failure.details['statusCode'], 401);
    },
  );

  test('expired refresh reports expiry without contacting server', () async {
    final storage = MemoryAuthSessionStorage(
      testAuthSession(
        expired: true,
      ).copyWith(refreshTokenExpiresAt: DateTime.utc(2000)),
    );
    final server = AuthTestHttpClient();
    final reporter = RecordingAuthErrorReporter();
    final repository = testAuthRepository(server, storage, reporter);
    addTearDown(repository.close);

    expect(await repository.refreshSession(), isNull);
    expect(server.refreshRequests, 0);
    expect(
      (reporter.errors.single as AuthAppError).details['clearReason'],
      'refresh_expired',
    );
  });

  test('refresh completing after logout cannot revive the session', () async {
    final response = Completer<HttpResponse>();
    final started = Completer<void>();
    final storage = MemoryAuthSessionStorage(testAuthSession(expired: true));
    final server = AuthTestHttpClient()
      ..onPost = (path, _) async {
        if (path == '/auth/logout') {
          return const HttpResponse(statusCode: 204, response: '');
        }
        started.complete();

        return response.future;
      };
    final repository = testAuthRepository(
      server,
      storage,
      RecordingAuthErrorReporter(),
    );
    addTearDown(repository.close);
    final refresh = repository.refreshSession();
    await started.future;
    await repository.signOut();
    response.complete(
      HttpResponse(statusCode: 200, response: testAuthResponse()),
    );

    expect(await refresh, isNull);
    expect(storage.session, isNull);
  });

  test('an old rejected refresh cannot clear a newer login', () async {
    final response = Completer<HttpResponse>();
    final started = Completer<void>();
    final storage = MemoryAuthSessionStorage(testAuthSession(expired: true));
    final server = AuthTestHttpClient()
      ..onPost = (path, _) async {
        if (path == '/auth/login') {
          return HttpResponse(
            statusCode: 200,
            response: testAuthResponse(suffix: 'login'),
          );
        }
        started.complete();

        return response.future;
      };
    final repository = testAuthRepository(
      server,
      storage,
      RecordingAuthErrorReporter(),
    );
    addTearDown(repository.close);
    final refresh = repository.refreshSession();
    await started.future;
    await repository.signIn(
      email: 'private@example.com',
      password: 'private-password',
    );
    response.complete(const HttpResponse(statusCode: 401, response: 'invalid'));
    await refresh;

    expect(storage.session!.refreshToken, 'secret-login-refresh');
    expect(storage.clears, 0);
  });

  test(
    'malformed auth response and credentials are never included in telemetry',
    () async {
      final storage = MemoryAuthSessionStorage(null);
      final server = AuthTestHttpClient()
        ..onPost = (_, _) async => const HttpResponse(
          statusCode: 200,
          response: '{"refreshToken":"TOP-SECRET"',
        );
      final reporter = RecordingAuthErrorReporter();
      final repository = testAuthRepository(server, storage, reporter);
      addTearDown(repository.close);

      await expectLater(
        repository.signIn(
          email: 'private@example.com',
          password: 'private-password',
        ),
        throwsA(isA<AuthAppError>()),
      );
      final telemetry =
          '${reporter.errors}${reporter.breadcrumbs.map((item) => item.data)}';
      expect(telemetry, isNot(contains('TOP-SECRET')));
      expect(telemetry, isNot(contains('private-password')));
      expect(telemetry, isNot(contains('private@example.com')));
    },
  );

  test(
    'broken error reporting cannot fail a successful login or restoration',
    () async {
      final storage = MemoryAuthSessionStorage(null);
      final repository = testAuthRepository(
        AuthTestHttpClient(),
        storage,
        RecordingAuthErrorReporter()..fail = true,
      );
      addTearDown(repository.close);

      expect(
        await repository.signIn(
          email: 'private@example.com',
          password: 'password',
        ),
        isNotNull,
      );
      expect(await repository.restoreSession(), isNotNull);
    },
  );
}
