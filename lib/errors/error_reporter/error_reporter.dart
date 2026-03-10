import 'package:esketit_music_app/errors/error_reporter/app_error.dart';

import 'breadcrumb.dart';

abstract class ErrorReporter {
  Future<void> addBreadcrumb(Breadcrumb breadcrumb);

  Future<void> reportError(AppError error);

  /// Removes user id if [id] is null.
  Future<void> setUserId(String? id);
}
