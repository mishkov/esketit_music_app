import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:http/http.dart' as http;

class HttpPackageHttpClient implements HttpClient {
  HttpPackageHttpClient({
    required this.baseUri,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<HttpResponse> get(String path) async {
    final response = await _client.get(_resolve(path));
    return HttpResponse(statusCode: response.statusCode, response: response.body);
  }

  Uri _resolve(String path) {
    final sanitizedPath = path.startsWith('/') ? path.substring(1) : path;
    return baseUri.resolve(sanitizedPath);
  }
}
