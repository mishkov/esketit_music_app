import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';

class AuthenticatedHttpClientProxy implements HttpClient {
  const AuthenticatedHttpClientProxy({
    required HttpClient httpClient,
    required AuthSessionRefresher sessionRefresher,
  }) : _httpClient = httpClient,
       _sessionRefresher = sessionRefresher;

  final HttpClient _httpClient;
  final AuthSessionRefresher _sessionRefresher;

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) {
    return _sendAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) => _httpClient.get(path, headers: mergedHeaders),
    );
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _sendAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) =>
          _httpClient.post(path, headers: mergedHeaders, body: body),
    );
  }

  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  }) {
    return _sendAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) =>
          _httpClient.postMultipart(path, headers: mergedHeaders, file: file),
    );
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _sendAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) =>
          _httpClient.put(path, headers: mergedHeaders, body: body),
    );
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    return _sendAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) => _httpClient.delete(path, headers: mergedHeaders),
    );
  }

  Future<HttpResponse> _sendAuthenticated({
    required String path,
    required Map<String, String>? headers,
    required Future<HttpResponse> Function(Map<String, String> headers) send,
  }) async {
    final session = await _sessionRefresher.refreshSession();
    if (session == null) {
      throw UnauthorizedAppError(path: path);
    }

    var response = await send(_authorizationHeaders(session, headers));
    if (response.statusCode == 401) {
      final refreshedSession = await _sessionRefresher.refreshSession(
        forceRefresh: true,
      );
      if (refreshedSession == null) {
        throw UnauthorizedAppError(path: path, responseBody: response.response);
      }

      response = await send(_authorizationHeaders(refreshedSession, headers));
    }

    _throwIfUnauthorizedOrForbidden(response, path: path);

    return response;
  }

  static Map<String, String> _authorizationHeaders(
    AuthSession session,
    Map<String, String>? headers,
  ) {
    return {...?headers, 'Authorization': 'Bearer ${session.accessToken}'};
  }

  static void _throwIfUnauthorizedOrForbidden(
    HttpResponse response, {
    required String path,
  }) {
    if (response.statusCode == 401) {
      throw UnauthorizedAppError(path: path, responseBody: response.response);
    }
    if (response.statusCode == 403) {
      throw ForbiddenAppError(path: path, responseBody: response.response);
    }
  }
}
