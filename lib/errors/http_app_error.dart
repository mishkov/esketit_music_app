import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error_level.dart';

class HttpAppError extends AppError {
  HttpAppError({
    required String message,
    required this.path,
    required this.statusCode,
    this.responseBody,
    Object? cause,
    StackTrace? stackTrace,
    AppErrorLevel level = const AppErrorLevel.regular(),
  }) : super(message, cause: cause, stackTrace: stackTrace, level: level);

  final String path;
  final int statusCode;
  final Object? responseBody;

  @override
  Map<String, Object?> describeDetails() => {
    'path': path,
    'statusCode': statusCode,
    'responseBody': responseBody,
    ...super.describeDetails(),
  };
}

class UnauthorizedAppError extends HttpAppError {
  UnauthorizedAppError({
    required super.path,
    super.responseBody,
    super.cause,
    super.stackTrace,
  }) : super(
         message: 'Unauthorized request',
         statusCode: 401,
         level: const AppErrorLevel.regular(),
       );
}

class ForbiddenAppError extends HttpAppError {
  ForbiddenAppError({
    required super.path,
    super.responseBody,
    super.cause,
    super.stackTrace,
  }) : super(
         message: 'Forbidden request',
         statusCode: 403,
         level: const AppErrorLevel.regular(),
       );
}
