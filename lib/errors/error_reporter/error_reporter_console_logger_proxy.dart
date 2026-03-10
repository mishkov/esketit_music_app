import 'dart:developer';

import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';

class ErrorReporterConsoleLoggerProxy implements ErrorReporter {
  final ErrorReporter _delegate;
  static const String _logName = 'ERROR_REPORTER';

  ErrorReporterConsoleLoggerProxy({required ErrorReporter delegate})
    : _delegate = delegate;

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    var logMessage = '${breadcrumb.category.name}:${breadcrumb.message}';

    if (breadcrumb.isStepToReproduce) {
      logMessage = '(STEP_TO_REPRODUCE) $logMessage';
    }

    if (breadcrumb.context != null && breadcrumb.context!.isNotEmpty) {
      logMessage += ' <in> ${breadcrumb.context}';
    }
    if (breadcrumb.data.isNotEmpty) {
      logMessage += ' <with> ${breadcrumb.data}';
    }

    log(logMessage, name: _logName);
    try {
      await _delegate.addBreadcrumb(breadcrumb);
    } catch (e, st) {
      log('Error while adding breadcrumb: $e', name: _logName, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> reportError(AppError error) async {
    log(error.toString(), name: _logName);
    try {
      await _delegate.reportError(error);
    } catch (e, st) {
      log('Error while reporting error: $e', name: _logName, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> setUserId(String? id) async {
    final action = id == null ? 'Removing user ID' : 'Setting user ID to "$id"';
    log(action, name: _logName);
    try {
      await _delegate.setUserId(id);
    } catch (e, st) {
      log('Error while $action: $e', name: _logName, stackTrace: st);
      rethrow;
    }
  }
}
