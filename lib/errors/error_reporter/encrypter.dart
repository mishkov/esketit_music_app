import 'dart:async';

abstract class Encrypter {
  Future<String> encrypt(String id);
}
