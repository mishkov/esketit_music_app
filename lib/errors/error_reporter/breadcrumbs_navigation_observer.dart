import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'breadcrumb.dart';
import 'category.dart';
import 'error_reporter.dart';

class BreadcrumbsNavigationObserver extends RouteObserver<PageRoute<Object?>> {
  final ErrorReporter _errorReporter;

  BreadcrumbsNavigationObserver(ErrorReporter errorReporter)
    : _errorReporter = errorReporter;

  @override
  void didPop(Route route, Route? previousRoute) {
    unawaited(
      _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'didPop',
          context: 'observer',
          category: Category.navigation,
          data: {
            'poppedRoute': _getNameOf(route),
            'newActiveRoute': _getNameOf(previousRoute),
          },
        ),
      ),
    );

    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    unawaited(
      _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'didPush',
          context: 'observer',
          category: Category.navigation,
          data: {
            'newRoute': _getNameOf(route),
            'previouslyActiveRoute': _getNameOf(previousRoute),
          },
        ),
      ),
    );

    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    unawaited(
      _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'didRemove',
          context: 'observer',
          category: Category.navigation,
          data: {
            'removedRoute': _getNameOf(route),
            'routeBelowRemoved': _getNameOf(previousRoute),
          },
        ),
      ),
    );

    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    unawaited(
      _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'didReplace',
          context: 'observer',
          category: Category.navigation,
          data: {
            'oldRoute': _getNameOf(oldRoute),
            'newRoute': _getNameOf(newRoute),
          },
        ),
      ),
    );

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  String _getNameOf(Route? route) {
    return route?.settings.name ?? route.runtimeType.toString();
  }
}
