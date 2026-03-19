import 'package:esketit_music_app/errors/error_reporter/app_error.dart';

class UnknownAuthAppError extends AppError {
  UnknownAuthAppError({super.cause, super.stackTrace})
    : super('Unknown auth error');
}
