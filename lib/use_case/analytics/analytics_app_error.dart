import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error_level.dart';

class AnalyticsAppError extends AppError {
  AnalyticsAppError(
    super.message, {
    this.context = const {},
    super.cause,
    super.stackTrace,
    super.level = const AppErrorLevel.regular(),
  });

  final Map<String, Object?> context;

  @override
  Map<String, Object?> describeDetails() => {
    ...context,
    ...super.describeDetails(),
  };
}
