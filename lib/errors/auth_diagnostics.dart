import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/auth/auth_session_diagnostics.dart';

class AuthDiagnostics implements AuthSessionDiagnostics {
  AuthDiagnostics(this._errorReporter);

  final ErrorReporter _errorReporter;
  final String _runId = DateTime.now()
      .toUtc()
      .microsecondsSinceEpoch
      .toString();
  int _operationNumber = 0;

  String nextOperationId() => '$_runId-${++_operationNumber}';

  @override
  Future<void> record(String message, Map<String, Object?> data) {
    return _safely(
      () => _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: message,
          context: 'authentication',
          data: {'authRunId': _runId, ...data},
        ),
      ),
    );
  }

  @override
  Future<AuthAppError> failure({
    required String operation,
    required String message,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> data = const {},
  }) async {
    final failure = AuthAppError.from(
      operation: operation,
      message: message,
      error: error,
      stackTrace: stackTrace,
      details: {'authRunId': _runId, ...data},
    );
    await _safely(() => _errorReporter.reportError(failure));

    return failure;
  }

  @override
  Future<void> setUserId(String? userId) {
    return _safely(() => _errorReporter.setUserId(userId));
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Telemetry failure must never change the authentication outcome.
    }
  }
}
