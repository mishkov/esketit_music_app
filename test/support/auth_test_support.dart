import 'dart:async';

import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/esketit_rest_api/auth/authenticated_http_client_proxy.dart';
import 'package:esketit_music_app/esketit_rest_api/auth/esketit_rest_api_auth_repository.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';

AuthSession testAuthSession({bool expired = false}) => AuthSession(
  user: AppUser(
    id: 1,
    email: 'private@example.com',
    role: AppUserRole.listener,
    createdAt: DateTime.utc(2026),
  ),
  accessToken: 'secret-old-access',
  accessTokenExpiresAt: DateTime.utc(expired ? 2000 : 2099),
  refreshToken: 'secret-old-refresh',
  refreshTokenExpiresAt: DateTime.utc(2100),
);

Map<String, Object> testUserResponse() => {
  'id': 1,
  'email': 'private@example.com',
  'role': 'listener',
  'createdAt': '2026-01-01T00:00:00Z',
};

Map<String, Object> testAuthResponse({String suffix = 'new'}) => {
  'user': testUserResponse(),
  'accessToken': 'secret-$suffix-access',
  'accessTokenExpiresAt': '2099-01-01T00:00:00Z',
  'refreshToken': 'secret-$suffix-refresh',
  'refreshTokenExpiresAt': '2100-01-01T00:00:00Z',
};

class RecordingAuthErrorReporter implements ErrorReporter {
  final errors = <AppError>[];
  final breadcrumbs = <Breadcrumb>[];
  final userIds = <String?>[];
  bool fail = false;

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    if (fail) throw StateError('reporter unavailable');
    breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> reportError(AppError error) async {
    if (fail) throw StateError('reporter unavailable');
    errors.add(error);
  }

  @override
  Future<void> setUserId(String? id) async {
    if (fail) throw StateError('reporter unavailable');
    userIds.add(id);
  }
}

class MemoryAuthSessionStorage implements AuthSessionStorage {
  MemoryAuthSessionStorage(this.session);
  AuthSession? session;
  Object? readError;
  Object? writeError;
  Object? clearError;
  Completer<AuthSession?>? readCompleter;
  Completer<void>? writeCompleter;
  int reads = 0;
  int clears = 0;
  final writes = <AuthSession>[];

  @override
  Future<AuthSession?> read() async {
    reads++;
    final error = readError;
    if (error != null) throw error;
    final operation = readCompleter;
    if (operation != null) return operation.future;

    return session;
  }

  @override
  Future<void> write(AuthSession session) async {
    final error = writeError;
    if (error != null) throw error;
    final operation = writeCompleter;
    if (operation != null) await operation.future;
    writes.add(session);
    this.session = session;
  }

  @override
  Future<void> clear() async {
    clears++;
    final error = clearError;
    if (error != null) throw error;
    session = null;
  }
}

class AuthTestHttpClient implements HttpClient {
  Future<HttpResponse> Function(String, Map<String, String>?)? onGet;
  Future<HttpResponse> Function(String, Object?)? onPost;
  int refreshRequests = 0;
  String currentRefreshToken = 'secret-old-refresh';
  bool rejectOldAccess = false;

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    final handler = onGet;
    if (handler != null) return handler(path, headers);
    if (rejectOldAccess &&
        headers?['Authorization'] == 'Bearer secret-old-access') {
      return const HttpResponse(statusCode: 401, response: 'expired');
    }

    return HttpResponse(statusCode: 200, response: testUserResponse());
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (path == '/auth/refresh') refreshRequests++;
    final handler = onPost;
    if (handler != null) return handler(path, body);
    if (path == '/auth/logout') {
      return const HttpResponse(statusCode: 204, response: '');
    }
    if (path == '/auth/refresh' &&
        (body as Map)['refreshToken'] != currentRefreshToken) {
      return const HttpResponse(statusCode: 401, response: 'invalid refresh');
    }
    currentRefreshToken = 'secret-new-refresh';

    return HttpResponse(statusCode: 200, response: testAuthResponse());
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) =>
      throw UnimplementedError();
  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) => throw UnimplementedError();
  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  }) => throw UnimplementedError();
}

EsketitRestApiAuthRepository testAuthRepository(
  AuthTestHttpClient server,
  MemoryAuthSessionStorage storage,
  RecordingAuthErrorReporter reporter,
) {
  final delegate = DelegatingAuthSessionRefresher();
  final repository = EsketitRestApiAuthRepository(
    unauthenticatedHttpClient: server,
    authenticatedHttpClient: AuthenticatedHttpClientProxy(
      httpClient: server,
      sessionRefresher: delegate,
    ),
    sessionStorage: storage,
    errorReporter: reporter,
  );
  delegate.setDelegate(repository);

  return repository;
}
