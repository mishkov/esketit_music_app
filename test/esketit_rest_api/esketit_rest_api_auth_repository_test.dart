import 'dart:async';

import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/auth/esketit_rest_api_auth_repository.dart';
import 'package:esketit_music_app/esketit_rest_api/auth/optionally_authenticated_http_client_proxy.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'invalid refresh clears the session and returns unauthenticated',
    () async {
      final sessionStorage = _MemoryAuthSessionStorage(_expiredAccessSession);
      final httpClient = _AuthHttpClient(
        refreshResponse: const HttpResponse(
          statusCode: 401,
          response: 'invalid refresh token',
        ),
      );
      final repository = EsketitRestApiAuthRepository(
        unauthenticatedHttpClient: httpClient,
        authenticatedHttpClient: httpClient,
        sessionStorage: sessionStorage,
      );

      expect(await repository.refreshSession(forceRefresh: true), isNull);
      expect(sessionStorage.session, isNull);
      expect(sessionStorage.clearCount, 1);
      expect(httpClient.refreshRequestCount, 1);

      expect(await repository.refreshSession(), isNull);
      expect(httpClient.refreshRequestCount, 1);
    },
  );

  test('concurrent refresh requests share one operation', () async {
    final refreshResponse = Completer<HttpResponse>();
    final sessionStorage = _MemoryAuthSessionStorage(_expiredAccessSession);
    final httpClient = _AuthHttpClient(
      refreshResponseOperation: refreshResponse.future,
    );
    final repository = EsketitRestApiAuthRepository(
      unauthenticatedHttpClient: httpClient,
      authenticatedHttpClient: httpClient,
      sessionStorage: sessionStorage,
    );

    final operations = [
      repository.refreshSession(forceRefresh: true),
      repository.refreshSession(forceRefresh: true),
      repository.refreshSession(forceRefresh: true),
    ];
    await Future<void>.delayed(Duration.zero);

    expect(httpClient.refreshRequestCount, 1);
    refreshResponse.complete(
      const HttpResponse(statusCode: 401, response: 'invalid refresh token'),
    );

    expect(await Future.wait(operations), [null, null, null]);
    expect(sessionStorage.clearCount, 1);
  });

  test(
    'restore treats a rejected current session as unauthenticated',
    () async {
      final sessionStorage = _MemoryAuthSessionStorage(_validAccessSession);
      final httpClient = _AuthHttpClient(
        getError: UnauthorizedAppError(path: '/auth/me'),
      );
      final repository = EsketitRestApiAuthRepository(
        unauthenticatedHttpClient: httpClient,
        authenticatedHttpClient: httpClient,
        sessionStorage: sessionStorage,
      );

      expect(await repository.restoreSession(), isNull);
      expect(sessionStorage.session, isNull);
      expect(sessionStorage.clearCount, 1);
    },
  );

  test(
    'optional request falls back anonymously after rejected refresh',
    () async {
      final sessionStorage = _MemoryAuthSessionStorage(_expiredAccessSession);
      final httpClient = _AuthHttpClient(
        refreshResponse: const HttpResponse(
          statusCode: 401,
          response: 'invalid refresh token',
        ),
      );
      final repository = EsketitRestApiAuthRepository(
        unauthenticatedHttpClient: httpClient,
        authenticatedHttpClient: httpClient,
        sessionStorage: sessionStorage,
      );
      final optionalClient = OptionallyAuthenticatedHttpClientProxy(
        httpClient: httpClient,
        sessionRefresher: repository,
      );

      final response = await optionalClient.get('/tracks');

      expect(response.statusCode, 200);
      expect(httpClient.refreshRequestCount, 1);
      expect(httpClient.getHeaders, [isNot(contains('Authorization'))]);
    },
  );

  test(
    'optional request clears a current-server rejection and retries anonymously',
    () async {
      final sessionStorage = _MemoryAuthSessionStorage(_validAccessSession);
      final httpClient = _AuthHttpClient(
        refreshResponse: const HttpResponse(
          statusCode: 401,
          response: 'invalid refresh token',
        ),
        rejectAuthorizedGets: true,
      );
      final repository = EsketitRestApiAuthRepository(
        unauthenticatedHttpClient: httpClient,
        authenticatedHttpClient: httpClient,
        sessionStorage: sessionStorage,
      );
      final optionalClient = OptionallyAuthenticatedHttpClientProxy(
        httpClient: httpClient,
        sessionRefresher: repository,
      );

      final response = await optionalClient.get('/tracks');

      expect(response.statusCode, 200);
      expect(httpClient.refreshRequestCount, 1);
      expect(sessionStorage.session, isNull);
      expect(httpClient.getHeaders, [
        contains('Authorization'),
        isNot(contains('Authorization')),
      ]);
    },
  );
}

final _user = AppUser(
  id: 1,
  email: 'listener@example.com',
  role: AppUserRole.listener,
  createdAt: DateTime.utc(2026),
);

final _expiredAccessSession = AuthSession(
  user: _user,
  accessToken: 'expired-access-token',
  accessTokenExpiresAt: DateTime.utc(2000),
  refreshToken: 'production-refresh-token',
  refreshTokenExpiresAt: DateTime.utc(2100),
);

final _validAccessSession = AuthSession(
  user: _user,
  accessToken: 'production-access-token',
  accessTokenExpiresAt: DateTime.utc(2099),
  refreshToken: 'production-refresh-token',
  refreshTokenExpiresAt: DateTime.utc(2100),
);

class _MemoryAuthSessionStorage implements AuthSessionStorage {
  _MemoryAuthSessionStorage(this.session);

  AuthSession? session;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    session = null;
  }

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async {
    this.session = session;
  }
}

class _AuthHttpClient implements HttpClient {
  _AuthHttpClient({
    this.refreshResponse,
    this.refreshResponseOperation,
    this.getError,
    this.rejectAuthorizedGets = false,
  });

  final HttpResponse? refreshResponse;
  final Future<HttpResponse>? refreshResponseOperation;
  final Object? getError;
  final bool rejectAuthorizedGets;
  int refreshRequestCount = 0;
  final List<Map<String, String>> getHeaders = [];

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    final error = getError;
    if (error != null) {
      throw error;
    }
    getHeaders.add(Map.of(headers ?? const {}));
    if (rejectAuthorizedGets && headers?.containsKey('Authorization') == true) {
      return const HttpResponse(statusCode: 401, response: 'unauthorized');
    }

    return const HttpResponse(statusCode: 200, response: {});
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (path != '/auth/refresh') {
      throw UnimplementedError('Unexpected POST $path');
    }
    refreshRequestCount += 1;

    return refreshResponseOperation ?? refreshResponse!;
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
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
}
