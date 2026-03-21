import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';

class OptionallyAuthenticatedHttpClientProxy implements HttpClient {
  const OptionallyAuthenticatedHttpClientProxy({
    required HttpClient httpClient,
    required this.refreshSession,
  }) : _httpClient = httpClient;

  final HttpClient _httpClient;
  final Future<AuthSession?> Function({bool forceRefresh}) refreshSession;

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) {
    return _sendOptionallyAuthenticated(
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
    return _sendOptionallyAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) =>
          _httpClient.post(path, headers: mergedHeaders, body: body),
    );
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _sendOptionallyAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) =>
          _httpClient.put(path, headers: mergedHeaders, body: body),
    );
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    return _sendOptionallyAuthenticated(
      path: path,
      headers: headers,
      send: (mergedHeaders) => _httpClient.delete(path, headers: mergedHeaders),
    );
  }

  Future<HttpResponse> _sendOptionallyAuthenticated({
    required String path,
    required Map<String, String>? headers,
    required Future<HttpResponse> Function(Map<String, String>? headers) send,
  }) async {
    final session = await refreshSession();
    if (session == null) {
      return send(headers);
    }

    var response = await send(_authorizationHeaders(session, headers));
    if (response.statusCode != 401) {
      return response;
    }

    final refreshedSession = await refreshSession(forceRefresh: true);
    if (refreshedSession == null) {
      return send(headers);
    }

    response = await send(_authorizationHeaders(refreshedSession, headers));
    if (response.statusCode == 401) {
      return send(headers);
    }

    return response;
  }

  static Map<String, String> _authorizationHeaders(
    AuthSession session,
    Map<String, String>? headers,
  ) {
    return {...?headers, 'Authorization': 'Bearer ${session.accessToken}'};
  }
}
