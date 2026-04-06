import 'dart:async';

import 'package:esketit_music_app/unassigned_layer/http_package_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'get trims a single leading slash before resolving the request URI',
    () async {
      final transport = _RecordingHttpClient();
      final client = HttpPackageHttpClient(
        baseUri: Uri.parse('http://localhost:8080/api/'),
        client: transport,
      );

      await client.get('/authors');

      expect(transport.requestedUris, [
        Uri.parse('http://localhost:8080/api/authors'),
      ]);
    },
  );

  test('get keeps paths without a leading slash unchanged', () async {
    final transport = _RecordingHttpClient();
    final client = HttpPackageHttpClient(
      baseUri: Uri.parse('http://localhost:8080/api/'),
      client: transport,
    );

    await client.get('authors');

    expect(transport.requestedUris, [
      Uri.parse('http://localhost:8080/api/authors'),
    ]);
  });
}

class _RecordingHttpClient extends http.BaseClient {
  final List<Uri> requestedUris = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUris.add(request.url);

    return http.StreamedResponse(Stream<List<int>>.empty(), 200);
  }
}
