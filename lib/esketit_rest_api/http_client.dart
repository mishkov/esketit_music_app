import 'package:esketit_music_app/esketit_rest_api/http_response.dart';

abstract class HttpClient {
  Future<HttpResponse> get(String path);
}
