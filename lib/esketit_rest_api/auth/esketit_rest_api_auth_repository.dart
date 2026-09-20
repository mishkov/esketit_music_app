import 'dart:async';
import 'dart:convert';

import 'package:esketit_music_app/domain/auth/app_user.dart';
import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/errors/auth_diagnostics.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/auth/auth_repository.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_persistence.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';

class EsketitRestApiAuthRepository implements AuthRepository {
  factory EsketitRestApiAuthRepository({
    required HttpClient unauthenticatedHttpClient,
    required HttpClient authenticatedHttpClient,
    required AuthSessionStorage sessionStorage,
    required ErrorReporter errorReporter,
  }) {
    final diagnostics = AuthDiagnostics(errorReporter);

    return EsketitRestApiAuthRepository._(
      unauthenticatedHttpClient,
      authenticatedHttpClient,
      diagnostics,
      AuthSessionPersistence(storage: sessionStorage, diagnostics: diagnostics),
    );
  }

  EsketitRestApiAuthRepository._(
    this._unauthenticatedHttpClient,
    this._authenticatedHttpClient,
    this._diagnostics,
    this._persistence,
  );

  final HttpClient _unauthenticatedHttpClient;
  final HttpClient _authenticatedHttpClient;
  final AuthDiagnostics _diagnostics;
  final AuthSessionPersistence _persistence;
  Future<AuthSession?>? _refreshOperation;
  Future<AuthSession?>? _restoreOperation;
  int _generation = 0;
  int _authenticationRevision = 0;

  @override
  Stream<AuthSession?> get sessionChanges => _persistence.changes;

  @override
  Future<AuthSession?> restoreSession() async {
    final existing = _restoreOperation;
    if (existing != null) return existing;
    final operation = _restoreSession();
    _restoreOperation = operation;
    try {
      return await operation;
    } finally {
      if (identical(operation, _restoreOperation)) _restoreOperation = null;
    }
  }

  Future<AuthSession?> _restoreSession() async {
    final stored = await _persistence.load();
    if (stored == null) {
      await _persistence.flush();

      return null;
    }
    final generation = _generation;
    await _diagnostics.record(
      'Restoring authentication session',
      _persistence.diagnosticContext,
    );
    try {
      final refreshed = await refreshSession();
      if (refreshed == null) return null;
      final response = await _request(
        'restore',
        '/auth/me',
        () => _authenticatedHttpClient.get('/auth/me'),
      );
      _checkResponse(response, '/auth/me');
      final user = _parseUser(
        _decodeJsonMap(response.response, path: '/auth/me'),
      );
      // /auth/me can refresh through its proxy. Always use the current tokens.
      final current = _persistence.current;
      if (current == null || generation != _generation) return current;
      await _persistence.save(current.copyWith(user: user));
      await _diagnostics.record(
        'Authentication session restored',
        _persistence.diagnosticContext,
      );

      return _persistence.current;
    } on UnauthorizedAppError {
      await _invalidate(
        'identity_rejected',
        path: '/auth/me',
        statusCode: 401,
        generation: generation,
      );

      return _persistence.current;
    } on ForbiddenAppError {
      await _invalidate(
        'identity_forbidden',
        path: '/auth/me',
        statusCode: 403,
        generation: generation,
      );

      return _persistence.current;
    } catch (error, stackTrace) {
      if (error is! AuthAppError) {
        await _diagnostics.failure(
          operation: 'restore',
          message: 'Failed to restore authentication session',
          error: error,
          stackTrace: stackTrace,
          data: _persistence.diagnosticContext,
        );
      }
      await _diagnostics.record(
        'Retaining authentication session after temporary restoration failure',
        _persistence.diagnosticContext,
      );

      return _persistence.current;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    return _authenticate('sign_in', '/auth/login', email, password);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) {
    return _authenticate('sign_up', '/auth/register', email, password);
  }

  Future<AuthSession> _authenticate(
    String operation,
    String path,
    String email,
    String password,
  ) async {
    final authenticationRevision = ++_authenticationRevision;
    try {
      final response = await _request(
        operation,
        path,
        () => _unauthenticatedHttpClient.post(
          path,
          body: {'email': email, 'password': password},
        ),
      );
      final session = _parseAuthResponse(response, path: path);
      if (authenticationRevision != _authenticationRevision) {
        throw AuthAppError(
          operation: operation,
          message: 'Authentication operation superseded',
          details: const {'failureKind': 'superseded'},
        );
      }
      ++_generation;
      _refreshOperation = null;
      await _diagnostics.setUserId(session.user.id.toString());
      await _persistence.save(session);
      await _diagnostics.record('Authentication succeeded', {
        'operation': operation,
        ..._persistence.diagnosticContext,
      });

      return session;
    } catch (error, stackTrace) {
      if (error is AuthAppError) rethrow;
      throw await _diagnostics.failure(
        operation: operation,
        message: 'Authentication failed',
        error: error,
        stackTrace: stackTrace,
        data: {'path': path, ..._persistence.diagnosticContext},
      );
    }
  }

  @override
  Future<void> signOut() async {
    ++_authenticationRevision;
    ++_generation;
    _refreshOperation = null;
    final current = _persistence.current;
    await _diagnostics.record(
      'User requested sign out',
      _persistence.diagnosticContext,
    );
    await _persistence.clear();
    try {
      if (current != null) {
        final response = await _request(
          'sign_out',
          '/auth/logout',
          () => _unauthenticatedHttpClient.post(
            '/auth/logout',
            body: {'refreshToken': current.refreshToken},
          ),
        );
        _checkResponse(response, '/auth/logout');
      }
    } catch (error, stackTrace) {
      if (error is! AuthAppError) {
        await _diagnostics.failure(
          operation: 'sign_out',
          message: 'Remote sign out failed',
          error: error,
          stackTrace: stackTrace,
          data: const {},
        );
      }
    }
    await _diagnostics.setUserId(null);
  }

  @override
  Future<AuthSession?> refreshSession({bool forceRefresh = false}) async {
    final existing = _refreshOperation;
    if (existing != null) return existing;
    await _persistence.load();
    await _persistence.flush();
    final operationAfterStorage = _refreshOperation;
    if (operationAfterStorage != null) return operationAfterStorage;
    final current = _persistence.current;
    if (current == null) return null;
    if (!forceRefresh && !current.isAccessTokenExpired) return current;
    final operation = _refreshSession(current, _generation, forceRefresh);
    _refreshOperation = operation;
    try {
      return await operation;
    } finally {
      if (identical(_refreshOperation, operation)) _refreshOperation = null;
    }
  }

  Future<AuthSession?> _refreshSession(
    AuthSession current,
    int generation,
    bool forced,
  ) async {
    if (current.isRefreshTokenExpired) {
      await _invalidate('refresh_expired', generation: generation);

      return _persistence.current;
    }
    try {
      final response = await _request(
        'refresh',
        '/auth/refresh',
        () => _unauthenticatedHttpClient.post(
          '/auth/refresh',
          body: {'refreshToken': current.refreshToken},
        ),
        extra: {'forced': forced},
      );
      if (generation != _generation) return _persistence.current;
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _invalidate(
          'refresh_rejected',
          path: '/auth/refresh',
          statusCode: response.statusCode,
          generation: generation,
        );

        return _persistence.current;
      }
      final refreshed = _parseAuthResponse(response, path: '/auth/refresh');
      await _persistence.save(refreshed);
      await _diagnostics.record(
        'Authentication tokens refreshed',
        _persistence.diagnosticContext,
      );

      return _persistence.current;
    } catch (error, stackTrace) {
      if (error is AuthAppError) rethrow;
      throw await _diagnostics.failure(
        operation: 'refresh',
        message: 'Failed to refresh authentication session',
        error: error,
        stackTrace: stackTrace,
        data: _persistence.diagnosticContext,
      );
    }
  }

  Future<void> _invalidate(
    String clearReason, {
    required int generation,
    String? path,
    int? statusCode,
  }) async {
    if (generation != _generation || _persistence.current == null) return;
    final context = {
      ..._persistence.diagnosticContext,
      'clearReason': clearReason,
      'path': ?path,
      'statusCode': ?statusCode,
    };
    await _diagnostics.record('Invalidating authentication session', context);
    await _diagnostics.failure(
      operation: 'invalidate',
      message: 'Authentication session invalidated',
      error: AuthAppError(
        operation: 'invalidate',
        message: 'Session rejected or expired',
        details: context,
      ),
      stackTrace: StackTrace.current,
      data: context,
    );
    if (generation != _generation) return;
    ++_generation;
    await _persistence.clear();
    await _diagnostics.setUserId(null);
  }

  Future<HttpResponse> _request(
    String operation,
    String path,
    Future<HttpResponse> Function() send, {
    Map<String, Object?> extra = const {},
  }) async {
    final context = {
      ..._persistence.diagnosticContext,
      ...extra,
      'operation': operation,
      'operationId': _diagnostics.nextOperationId(),
      'path': path,
    };
    await _diagnostics.record('Authentication request started', context);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await send();
      await _diagnostics.record('Authentication request completed', {
        ...context,
        'statusCode': response.statusCode,
        'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
      });

      return response;
    } catch (error, stackTrace) {
      // Preserve the status classification used by restoration after /auth/me.
      if (error is UnauthorizedAppError || error is ForbiddenAppError) rethrow;
      if (error is AuthAppError) rethrow;
      throw await _diagnostics.failure(
        operation: operation,
        message: 'Authentication request failed',
        error: error,
        stackTrace: stackTrace,
        data: {
          ...context,
          'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
          'sessionRetained': _persistence.current != null,
        },
      );
    }
  }

  void _checkResponse(HttpResponse response, String path) {
    _throwIfUnauthorizedOrForbidden(response, path: path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpAppError(
        message: 'Authentication request failed',
        path: path,
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> close() => _persistence.close();

  AuthSession _parseAuthResponse(
    HttpResponse response, {
    required String path,
  }) {
    _throwIfUnauthorizedOrForbidden(response, path: path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpAppError(
        message: 'Request failed',
        path: path,
        statusCode: response.statusCode,
      );
    }

    final body = _decodeJsonMap(response.response, path: path);

    return AuthSession(
      user: _parseUser(_jsonMap(body['user'], path: path, fieldName: 'user')),
      accessToken: body['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        body['accessTokenExpiresAt'] as String,
      ),
      refreshToken: body['refreshToken'] as String,
      refreshTokenExpiresAt: DateTime.parse(
        body['refreshTokenExpiresAt'] as String,
      ),
    );
  }

  AppUser _parseUser(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      role: AppUserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => AppUserRole.listener,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> _decodeJsonMap(Object? body, {required String path}) {
    final decoded = body is String ? jsonDecode(body) : body;
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object response for $path');
    }

    return decoded;
  }

  Map<String, dynamic> _jsonMap(
    Object? value, {
    required String path,
    required String fieldName,
  }) {
    if (value is! Map<String, dynamic>) {
      throw FormatException(
        'Expected $fieldName to be a JSON object for $path',
      );
    }

    return value;
  }

  void _throwIfUnauthorizedOrForbidden(
    HttpResponse response, {
    required String path,
  }) {
    if (response.statusCode == 401) {
      throw UnauthorizedAppError(path: path);
    }
    if (response.statusCode == 403) {
      throw ForbiddenAppError(path: path);
    }
  }
}
