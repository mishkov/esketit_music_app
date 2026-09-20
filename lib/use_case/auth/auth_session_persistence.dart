import 'dart:async';

import 'package:esketit_music_app/domain/auth/auth_session.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_diagnostics.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_storage.dart';

/// Serializes storage operations and keeps newly rotated credentials available
/// while a failed write is pending. A stale read/write cannot replace a newer
/// login or undo a logout.
class AuthSessionPersistence {
  AuthSessionPersistence({
    required AuthSessionStorage storage,
    required AuthSessionDiagnostics diagnostics,
  }) : _storage = storage,
       _diagnostics = diagnostics;

  final AuthSessionStorage _storage;
  final AuthSessionDiagnostics _diagnostics;
  final _changes = StreamController<AuthSession?>.broadcast();
  Future<void> _storageOperation = Future<void>.value();
  AuthSession? _session;
  bool _loaded = false;
  bool _pending = false;
  bool _closed = false;
  int _revision = 0;
  int _writeFailures = 0;
  Timer? _retryTimer;

  static const _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 2),
  ];

  AuthSession? get current => _session;
  Stream<AuthSession?> get changes => _changes.stream;
  Map<String, Object?> get diagnosticContext => {
    'hasSession': _session != null,
    'storageLoaded': _loaded,
    'persistencePending': _pending,
    'storageRevision': _revision,
    if (_session case final session?) ...{
      'accessExpiresAt': session.accessTokenExpiresAt.toUtc().toIso8601String(),
      'refreshExpiresAt': session.refreshTokenExpiresAt
          .toUtc()
          .toIso8601String(),
      'accessExpired': session.isAccessTokenExpired,
      'refreshExpired': session.isRefreshTokenExpired,
    },
  };

  Future<AuthSession?> load() async {
    await _enqueue(() async {
      if (_loaded || _closed) return;
      final revision = _revision;
      await _diagnostics.record(
        'Reading saved authentication session',
        diagnosticContext,
      );
      try {
        final stored = await _storage.read();
        if (revision != _revision) return;
        _session = stored;
        _loaded = true;
        await _diagnostics.setUserId(stored?.user.id.toString());
        await _diagnostics.record(
          'Saved authentication session read',
          diagnosticContext,
        );
      } catch (error, stackTrace) {
        throw await _diagnostics.failure(
          operation: 'storage.read',
          message: 'Failed to read authentication session',
          error: error,
          stackTrace: stackTrace,
          data: diagnosticContext,
        );
      }
    });

    return _session;
  }

  Future<void> save(AuthSession session) {
    _replace(session);

    return flush();
  }

  Future<void> clear() {
    _replace(null);

    return flush();
  }

  void _replace(AuthSession? session) {
    if (_closed) return;
    _session = session;
    _loaded = true;
    _pending = true;
    _revision++;
    _writeFailures = 0;
    _retryTimer?.cancel();
    _changes.add(session);
  }

  Future<void> flush() => _enqueue(_flush);

  Future<void> _flush() async {
    if (!_pending || _closed) return;
    final revision = _revision;
    final session = _session;
    final operation = session == null ? 'storage.clear' : 'storage.write';
    final context = {...diagnosticContext, 'attempt': _writeFailures + 1};
    await _diagnostics.record('Persisting authentication session', context);
    try {
      if (session == null) {
        await _storage.clear();
      } else {
        await _storage.write(session);
      }
      if (revision != _revision) return;
      _pending = false;
      _retryTimer?.cancel();
      await _diagnostics.record('Authentication session persisted', {
        ...diagnosticContext,
        'previousFailures': _writeFailures,
      });
      _writeFailures = 0;
    } catch (error, stackTrace) {
      if (revision != _revision) return;
      _writeFailures++;
      await _diagnostics.failure(
        operation: operation,
        message: 'Failed to persist authentication session',
        error: error,
        stackTrace: stackTrace,
        data: {...context, 'willRetry': true},
      );
      if (_writeFailures <= _retryDelays.length && !_closed) {
        _retryTimer?.cancel();
        _retryTimer = Timer(
          _retryDelays[_writeFailures - 1],
          () => unawaited(flush()),
        );
      }
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _storageOperation.then((_) => action());
    _storageOperation = next.catchError((Object _) {});

    return next;
  }

  Future<void> close() async {
    _closed = true;
    _retryTimer?.cancel();
    await _storageOperation;
    await _changes.close();
  }
}
