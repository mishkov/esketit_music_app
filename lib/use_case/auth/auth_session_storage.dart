import 'package:esketit_music_app/domain/auth/auth_session.dart';

abstract class AuthSessionStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}
