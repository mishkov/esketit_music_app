import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/esketit_rest_api/auth/optionally_authenticated_http_client_proxy.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/playlists/esketit_rest_api_playlists_storage.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public and shared playlist track requests include optional authentication',
    () async {
      final httpClient = _ShareablePlaylistHttpClient();
      final storage = EsketitRestApiPlaylistsStorage(
        httpClient: OptionallyAuthenticatedHttpClientProxy(
          httpClient: httpClient,
          sessionRefresher: _FakeSessionRefresher(_session),
        ),
        baseUri: Uri.parse('http://localhost:8080/api/'),
      );

      await storage.getPublicPlaylistDetails(playlistId: 7);
      await storage.getSharedPlaylistDetails(shareToken: 'share-token');

      expect(
        httpClient.headersFor(
          '/public/playlists/7/tracks?page=1&pageSize=100',
        )['Authorization'],
        'Bearer access-token',
      );
      expect(
        httpClient.headersFor(
          '/shared/playlists/share-token/tracks?page=1&pageSize=100',
        )['Authorization'],
        'Bearer access-token',
      );
    },
  );

  test('shareable playlist requests remain available anonymously', () async {
    final httpClient = _ShareablePlaylistHttpClient();
    final storage = EsketitRestApiPlaylistsStorage(
      httpClient: OptionallyAuthenticatedHttpClientProxy(
        httpClient: httpClient,
        sessionRefresher: _FakeSessionRefresher(null),
      ),
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    await storage.getPublicPlaylistDetails(playlistId: 7);
    await storage.getSharedPlaylistDetails(shareToken: 'share-token');

    expect(
      httpClient.headersFor('/public/playlists/7/tracks?page=1&pageSize=100'),
      isNot(contains('Authorization')),
    );
    expect(
      httpClient.headersFor(
        '/shared/playlists/share-token/tracks?page=1&pageSize=100',
      ),
      isNot(contains('Authorization')),
    );
  });
}

final _session = AuthSession(
  user: AppUser(
    id: 1,
    email: 'listener@example.com',
    role: AppUserRole.listener,
    createdAt: DateTime.utc(2026),
  ),
  accessToken: 'access-token',
  accessTokenExpiresAt: DateTime.utc(2099),
  refreshToken: 'refresh-token',
  refreshTokenExpiresAt: DateTime.utc(2100),
);

class _FakeSessionRefresher implements AuthSessionRefresher {
  const _FakeSessionRefresher(this.session);

  final AuthSession? session;

  @override
  Future<AuthSession?> refreshSession({bool forceRefresh = false}) async {
    return session;
  }
}

class _ShareablePlaylistHttpClient implements HttpClient {
  final List<({String path, Map<String, String> headers})> requests = [];

  Map<String, String> headersFor(String path) {
    return requests.lastWhere((request) => request.path == path).headers;
  }

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    requests.add((path: path, headers: Map.of(headers ?? const {})));

    if (path == '/authors') {
      return const HttpResponse(statusCode: 200, response: []);
    }
    if (path.endsWith('/tracks?page=1&pageSize=100')) {
      return const HttpResponse(
        statusCode: 200,
        response: {
          'items': [],
          'page': 1,
          'pageSize': 100,
          'totalItems': 0,
          'totalPages': 1,
        },
      );
    }

    return HttpResponse(
      statusCode: 200,
      response: {
        'id': path.startsWith('/public/') ? 7 : 8,
        'userId': 1,
        'name': 'Shareable playlist',
        'description': '',
        'coverImagePath': '',
        'visibility': path.startsWith('/public/') ? 'public' : 'shared',
        'trackCount': 0,
        'system': false,
        'kind': 'custom',
        'isFavorites': false,
      },
    );
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
