import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error_level.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';

/// Authentication diagnostics deliberately exclude raw exceptions and bodies:
/// parser errors and server responses can contain credentials.
class AuthAppError extends AppError {
  AuthAppError({
    required this.operation,
    required String message,
    this.details = const {},
    super.stackTrace,
  }) : super(message, level: const AppErrorLevel.regular());

  final String operation;
  final Map<String, Object?> details;

  factory AuthAppError.from({
    required String operation,
    required String message,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> details = const {},
  }) {
    return AuthAppError(
      operation: operation,
      message: message,
      stackTrace: stackTrace,
      details: {
        'errorType': error.runtimeType.toString(),
        if (error is AuthAppError) ...error.details,
        if (error is HttpAppError) 'statusCode': error.statusCode,
        'failureKind': _failureKind(error),
        ...details,
      },
    );
  }

  static String _failureKind(Object error) {
    if (error is AuthAppError) {
      return error.details['failureKind'] as String? ?? 'authentication';
    }
    if (error is HttpAppError) return 'http';
    if (error is FormatException || error is TypeError) return 'invalid_data';

    // Classify transport failures without recording exception text or URLs.
    final description = error.toString().toLowerCase();
    if (description.contains('bad file descriptor')) return 'socket_closed';
    if (description.contains("can't assign requested address")) {
      return 'network_address_unavailable';
    }
    if (description.contains('failed host lookup')) return 'dns_failure';
    if (description.contains('timeout')) return 'timeout';

    return 'unexpected';
  }

  @override
  Map<String, Object?> describeDetails() => {
    ...super.describeDetails(),
    'operation': operation,
    ...details,
  };
}
