import 'dart:convert';

import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlutterSecureAuthSessionStorage implements AuthSessionStorage {
  FlutterSecureAuthSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _sessionKey = 'auth_session_v1';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<AuthSession?> read() async {
    final rawSession = await _secureStorage.read(key: _sessionKey);
    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    final json = jsonDecode(rawSession);
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      return null;
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
  Future<void> write(AuthSession session) {
    return _secureStorage.write(
      key: _sessionKey,
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
  }

  @override
  Future<void> clear() => _secureStorage.delete(key: _sessionKey);

  AppUserRole _parseRole(String value) {
    return AppUserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppUserRole.listener,
    );
  }
}
