import 'package:esketit_music_app/errors/error_reporter/encrypter.dart';

class EncrypterStub implements Encrypter {
  @override
  Future<String> encrypt(String id) async => id;
}
