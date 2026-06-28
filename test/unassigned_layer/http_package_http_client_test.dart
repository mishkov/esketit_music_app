import 'dart:async';
import 'dart:convert';

import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
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

  test('get resolves against a root-relative base URI', () async {
    final transport = _RecordingHttpClient();
    final client = HttpPackageHttpClient(
      baseUri: Uri.parse('/api/'),
      client: transport,
    );

    await client.get('authors');

    expect(transport.requestedUris, [Uri.parse('/api/authors')]);
  });

  test('postMultipart sends multipart request with resolved URI', () async {
    final transport = _RecordingHttpClient(
      responseBody: 'uploaded',
      statusCode: 201,
    );
    final client = HttpPackageHttpClient(
      baseUri: Uri.parse('http://localhost:8080/api/'),
      client: transport,
    );

    final response = await client.postMultipart(
      '/playlists/7/cover',
      headers: {'Authorization': 'Bearer token'},
      file: const MultipartFileData(
        fieldName: 'file',
        fileName: 'cover.png',
        bytes: [1, 2, 3],
      ),
    );

    final request = transport.requests.single as http.MultipartRequest;
    expect(
      request.url,
      Uri.parse('http://localhost:8080/api/playlists/7/cover'),
    );
    expect(request.headers['Authorization'], 'Bearer token');
    expect(request.files.single.field, 'file');
    expect(request.files.single.filename, 'cover.png');
    expect(response.statusCode, 201);
    expect(response.response, 'uploaded');
  });
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient({this.responseBody = '', this.statusCode = 200});

  final List<Uri> requestedUris = <Uri>[];
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final String responseBody;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUris.add(request.url);
    requests.add(request);

    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(responseBody)),
      statusCode,
    );
  }
}
