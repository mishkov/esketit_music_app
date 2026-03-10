import 'dart:async';

import 'package:flutter/widgets.dart';

import 'breadcrumb.dart';
import 'category.dart';
import 'error_reporter.dart';

class GestureNavigationObserver extends NavigatorObserver {
  final ErrorReporter _errorReporter;

  bool _didPop = false;

  GestureNavigationObserver({required ErrorReporter errorReporter})
    : _errorReporter = errorReporter;

  @override
  void didStartUserGesture(
    Route<Object?> route,
    Route<Object?>? previousRoute,
  ) {
    _addBreadcrumb('Start user navigation gesture');

    _didPop = false;
  }

  @override
  void didStopUserGesture() {
    _addBreadcrumb('Stop user navigation gesture');

    if (_didPop) {
      _addBreadcrumb('Close screen via gesture');
    }
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    _didPop = true;
  }

  void _addBreadcrumb(String message) {
    unawaited(
      _errorReporter.addBreadcrumb(
        Breadcrumb(message: message, category: Category.uiClick),
      ),
    );
  }
}
