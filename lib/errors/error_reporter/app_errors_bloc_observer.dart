import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';

class AppErrorsBlocObserver extends BlocObserver {
  final ErrorReporter _reporter;

  AppErrorsBlocObserver({required ErrorReporter reporter})
    : _reporter = reporter;

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    final wrappedError = AppError(
      'Unexpected error in ${bloc.runtimeType} bloc',
      cause: error,
      stackTrace: stackTrace,
    );

    unawaited(_reporter.reportError(wrappedError));

    super.onError(bloc, error, stackTrace);
  }
}
