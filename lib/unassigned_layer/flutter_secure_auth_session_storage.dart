import 'dart:convert';

import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';
import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureAuthSessionStorage implements AuthSessionStorage {
  FlutterSecureAuthSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _legacySessionKey = 'auth_session_v1';
  static const _backgroundSessionKey = 'auth_session_v2';
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  bool get _usesIosKeychain =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String get _sessionKey =>
      _usesIosKeychain ? _backgroundSessionKey : _legacySessionKey;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<AuthSession?> read() => _perform('storage.read', () async {
    var rawSession = await _secureStorage.read(
      key: _sessionKey,
      iOptions: _iosOptions,
    );
    if (rawSession == null && _usesIosKeychain) {
      // Version 9 of the plugin can return null for an inaccessible item. Do
      // not interpret an unavailable legacy Keychain entry as a signed-out user.
      if (await _secureStorage.isCupertinoProtectedDataAvailable() == false) {
        throw AuthAppError(
          operation: 'storage.read',
          message: 'Protected authentication data is unavailable',
          details: const {
            'failureKind': 'protected_data_unavailable',
            'protectedDataAvailable': false,
          },
        );
      }
      rawSession = await _secureStorage.read(key: _legacySessionKey);
      if (rawSession != null) {
        final session = _parseSession(rawSession);
        // Write a different key first. Changing accessibility in-place in the
        // plugin deletes the old item before attempting to create its replacement.
        await write(session);

        return session;
      }
    }
    if (rawSession == null) return null;

    return _parseSession(rawSession);
  });

  AuthSession _parseSession(String rawSession) {
    final json = jsonDecode(rawSession);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved authentication session');
    }

    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved authentication user');
    }

    return AuthSession(
      user: AppUser(
        id: (userJson['id'] as num).toInt(),
        email: userJson['email'] as String,
        role: _parseRole(userJson['role'] as String),
        createdAt: DateTime.parse(userJson['createdAt'] as String),
      ),
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ),
    );
  }

  @override
  Future<void> write(
    AuthSession session,
  ) => _perform('storage.write', () async {
    await _secureStorage.write(
      key: _sessionKey,
      iOptions: _iosOptions,
      value: jsonEncode({
        'user': {
          'id': session.user.id,
          'email': session.user.email,
          'role': session.user.role.name,
          'createdAt': session.user.createdAt.toIso8601String(),
        },
        'accessToken': session.accessToken,
        'accessTokenExpiresAt': session.accessTokenExpiresAt.toIso8601String(),
        'refreshToken': session.refreshToken,
        'refreshTokenExpiresAt': session.refreshTokenExpiresAt
            .toIso8601String(),
      }),
    );
    if (_usesIosKeychain) await _secureStorage.delete(key: _legacySessionKey);
  });

  @override
  Future<void> clear() => _perform('storage.clear', () async {
    // Remove the fallback first so a partial clear cannot restore the old login.
    if (_usesIosKeychain) await _secureStorage.delete(key: _legacySessionKey);
    await _secureStorage.delete(key: _sessionKey, iOptions: _iosOptions);
  });

  Future<T> _perform<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on AuthAppError {
      rethrow;
    } on PlatformException catch (error, stackTrace) {
      bool? protectedDataAvailable;
      if (_usesIosKeychain) {
        try {
          protectedDataAvailable = await _secureStorage
              .isCupertinoProtectedDataAvailable();
        } catch (_) {
          // The original storage error is the useful failure to preserve.
        }
      }
      final nativeCode =
          int.tryParse(error.details.toString()) ??
          int.tryParse(
            RegExp(
                  r'Code: (-?\d+)',
                ).firstMatch(error.message ?? '')?.group(1) ??
                '',
          );
      throw AuthAppError(
        operation: operation,
        message: 'Secure authentication storage failed',
        stackTrace: stackTrace,
        details: {
          'failureKind': 'secure_storage',
          'platformErrorCode': error.code,
          'nativeErrorCode': nativeCode,
          'protectedDataAvailable': protectedDataAvailable,
          'keychainAccessibility': 'first_unlock_this_device',
        },
      );
    } catch (error, stackTrace) {
      throw AuthAppError.from(
        operation: operation,
        message: 'Invalid saved authentication data',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  AppUserRole _parseRole(String value) {
    return AppUserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppUserRole.listener,
    );
  }
}
