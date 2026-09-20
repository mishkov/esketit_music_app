import 'dart:async';

import 'package:esketit_music_app/errors/auth_diagnostics.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_support.dart';

void main() {
  test('stale storage read cannot overwrite a newer login', () async {
    final stored = testAuthSession();
    final loggedIn = stored.copyWith(refreshToken: 'new-login');
    final storage = MemoryAuthSessionStorage(stored)
      ..readCompleter = Completer();
    final persistence = AuthSessionPersistence(
      storage: storage,
      diagnostics: AuthDiagnostics(RecordingAuthErrorReporter()),
    );
    addTearDown(persistence.close);
    final load = persistence.load();
    await Future<void>.delayed(Duration.zero);
    final save = persistence.save(loggedIn);
    storage.readCompleter!.complete(stored);
    await Future.wait([load, save]);

    expect(persistence.current, loggedIn);
    expect(storage.session, loggedIn);
  });

  test('logout is serialized after a write already in progress', () async {
    final storage = MemoryAuthSessionStorage(null)
      ..writeCompleter = Completer();
    final persistence = AuthSessionPersistence(
      storage: storage,
      diagnostics: AuthDiagnostics(RecordingAuthErrorReporter()),
    );
    addTearDown(persistence.close);
    final save = persistence.save(testAuthSession());
    await Future<void>.delayed(Duration.zero);
    final clear = persistence.clear();
    storage.writeCompleter!.complete();
    await Future.wait([save, clear]);

    expect(persistence.current, isNull);
    expect(storage.session, isNull);
  });

  test('failed clear stays pending and never reloads the old login', () async {
    final storage = MemoryAuthSessionStorage(testAuthSession())
      ..clearError = StateError('temporarily unavailable');
    final persistence = AuthSessionPersistence(
      storage: storage,
      diagnostics: AuthDiagnostics(RecordingAuthErrorReporter()),
    );
    addTearDown(persistence.close);
    await persistence.load();
    await persistence.clear();

    expect(await persistence.load(), isNull);
    expect(persistence.diagnosticContext['persistencePending'], isTrue);
    storage.clearError = null;
    await persistence.flush();
    expect(storage.session, isNull);
    expect(persistence.diagnosticContext['persistencePending'], isFalse);
  });
}
