import 'dart:convert';

import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/unassigned_layer/flutter_secure_auth_session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_test_support.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'migrates legacy credentials only after saving the new background-accessible entry',
    () async {
      final keychain = _FakeKeychain()
        ..values['auth_session_v1'] = jsonEncode(
          testAuthResponse(suffix: 'old'),
        );
      final storage = FlutterSecureAuthSessionStorage(secureStorage: keychain);

      expect((await storage.read())!.refreshToken, 'secret-old-refresh');
      expect(keychain.operations, [
        'read:auth_session_v2',
        'read:auth_session_v1',
        'write:auth_session_v2',
        'delete:auth_session_v1',
      ]);
      expect(
        keychain.lastWriteOptions!.toMap()['accessibility'],
        'first_unlock_this_device',
      );
      expect(keychain.values.containsKey('auth_session_v1'), isFalse);
      expect(keychain.values.containsKey('auth_session_v2'), isTrue);
    },
  );

  test(
    'failed migration retains legacy credentials and reports native status safely',
    () async {
      final keychain = _FakeKeychain()
        ..values['auth_session_v1'] = jsonEncode(
          testAuthResponse(suffix: 'old'),
        )
        ..writeError = PlatformException(
          code: 'Unexpected security result code',
          message: 'Code: -25308, Message: User interaction is not allowed.',
          details: -25308,
        );
      final storage = FlutterSecureAuthSessionStorage(secureStorage: keychain);

      await expectLater(
        storage.read(),
        throwsA(
          isA<AuthAppError>()
              .having(
                (error) => error.details['nativeErrorCode'],
                'native code',
                -25308,
              )
              .having(
                (error) => error.details['protectedDataAvailable'],
                'protected data',
                true,
              ),
        ),
      );
      expect(keychain.values.containsKey('auth_session_v1'), isTrue);
      expect(
        keychain.operations.any((operation) => operation.startsWith('delete:')),
        isFalse,
      );
      keychain.writeError = null;
      expect(await storage.read(), isNotNull);
    },
  );

  test(
    'reads migrated credentials while protected foreground data is unavailable',
    () async {
      final keychain = _FakeKeychain()
        ..values['auth_session_v2'] = jsonEncode(testAuthResponse())
        ..protectedDataAvailable = false;

      expect(
        await FlutterSecureAuthSessionStorage(secureStorage: keychain).read(),
        isNotNull,
      );
      expect(keychain.operations, ['read:auth_session_v2']);
    },
  );

  test(
    'inaccessible legacy credentials produce a recoverable error instead of missing session',
    () async {
      final keychain = _FakeKeychain()
        ..values['auth_session_v1'] = jsonEncode(testAuthResponse())
        ..protectedDataAvailable = false;

      await expectLater(
        FlutterSecureAuthSessionStorage(secureStorage: keychain).read(),
        throwsA(
          isA<AuthAppError>().having(
            (error) => error.details['failureKind'],
            'failure kind',
            'protected_data_unavailable',
          ),
        ),
      );
      expect(keychain.values.containsKey('auth_session_v1'), isTrue);
    },
  );

  test('clear deletes legacy fallback before the migrated entry', () async {
    final keychain = _FakeKeychain()
      ..values['auth_session_v1'] = 'legacy'
      ..values['auth_session_v2'] = 'current';
    await FlutterSecureAuthSessionStorage(secureStorage: keychain).clear();

    expect(keychain.operations, [
      'delete:auth_session_v1',
      'delete:auth_session_v2',
    ]);
    expect(keychain.values, isEmpty);
  });

  test('malformed saved JSON does not leak its contents', () async {
    final keychain = _FakeKeychain()
      ..values['auth_session_v2'] = '{"refreshToken":"TOP-SECRET"';

    await expectLater(
      FlutterSecureAuthSessionStorage(secureStorage: keychain).read(),
      throwsA(
        isA<AuthAppError>().having(
          (error) => error.toString(),
          'safe diagnostic',
          isNot(contains('TOP-SECRET')),
        ),
      ),
    );
  });

  test('other platforms continue using their existing session key', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final keychain = _FakeKeychain();
    final storage = FlutterSecureAuthSessionStorage(secureStorage: keychain);
    await storage.write(testAuthSession());

    expect(keychain.values.keys, ['auth_session_v1']);
    expect(await storage.read(), testAuthSession());
  });
}

class _FakeKeychain extends FlutterSecureStorage {
  final values = <String, String>{};
  final operations = <String>[];
  bool protectedDataAvailable = true;
  PlatformException? writeError;
  IOSOptions? lastWriteOptions;

  @override
  Future<bool?> isCupertinoProtectedDataAvailable() async =>
      protectedDataAvailable;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('read:$key');

    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('write:$key');
    final error = writeError;
    if (error != null) throw error;
    lastWriteOptions = iOptions;
    values[key] = value!;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    operations.add('delete:$key');
    values.remove(key);
  }
}
