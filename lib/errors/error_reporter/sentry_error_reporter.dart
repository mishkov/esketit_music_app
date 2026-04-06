import 'dart:async';

import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/encrypter.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:sentry_flutter/sentry_flutter.dart' as sentry;

class SentryErrorReporter implements ErrorReporter {
  final Encrypter _encrypter;

  SentryErrorReporter({required Encrypter encrypter}) : _encrypter = encrypter;

  Future<void> init({
    required String dsn,
    required FutureOr<void> Function()? appRunner,
  }) async {
    await sentry.SentryFlutter.init((options) {
      // This way of mutating parameter is used by official documentaiton
      // https://pub.dev/packages/sentry_flutter.
      options.dsn = dsn;
    }, appRunner: appRunner);
  }

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    var message = breadcrumb.message;
    if (breadcrumb.context != null && breadcrumb.context!.isNotEmpty) {
      message += ' <in context:> ${breadcrumb.context}';
    }

    var category = switch (breadcrumb.category) {
      Category.http => 'http',
      Category.generic => 'info',
      Category.uiClick => 'ui.click',
      Category.uiInput => 'ui.input',
      Category.stateHandler => 'state.handler',
      Category.navigation => 'navigation',
    };

    if (breadcrumb.isStepToReproduce) {
      category += ' (step_to_reproduce)';
    }

    await sentry.Sentry.addBreadcrumb(
      sentry.Breadcrumb(
        message: message,
        data: breadcrumb.data,
        category: category,
      ),
    );
  }

  @override
  Future<void> reportError(AppError error) async {
    await sentry.Sentry.captureException(error, stackTrace: error.stackTrace);
  }

  @override
  Future<void> setUserId(String? id) async {
    await sentry.Sentry.configureScope((scope) async {
      final String finalId;
      if (id != null) {
        finalId = await _encrypter.encrypt(id);
      } else {
        finalId = '';
      }

      await scope.setUser(sentry.SentryUser(id: finalId));
    });
  }
}
