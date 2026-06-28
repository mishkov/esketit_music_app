import 'package:esketit_music_app/esketit_rest_api/http_response.dart';

class MultipartFileData {
  const MultipartFileData({
    required this.fieldName,
    required this.fileName,
    required this.bytes,
  });

  final String fieldName;
  final String fileName;
  final List<int> bytes;
}

abstract class HttpClient {
  Future<HttpResponse> get(String path, {Map<String, String>? headers});

  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  });

  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });

  Future<HttpResponse> delete(String path, {Map<String, String>? headers});
}
