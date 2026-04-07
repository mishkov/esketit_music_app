import 'package:esketit_music_app/unassigned_layer/base_uri_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse returns a URI when the value contains scheme and host', () {
    expect(
      BaseUriConfiguration.parse('http://localhost:8080'),
      Uri.parse('http://localhost:8080'),
    );
  });

  test('parse throws when the value does not contain a host', () {
    expect(
      () => BaseUriConfiguration.parse('localhost:8080'),
      throwsA(isA<FormatException>()),
    );
  });
}
