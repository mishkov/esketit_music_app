import 'package:meta/meta.dart';

import 'app_error_level.dart';

class AppError implements Exception {
  final String message;
  final AppErrorLevel level;
  final Object? cause;
  final StackTrace stackTrace;

  AppError(
    this.message, {
    this.level = const AppErrorLevel.fatal(),
    this.cause,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;

  List<Object> get causeChain {
    final chain = <Object>[this];

    var childError = cause;
    while (childError != null) {
      chain.add(childError);

      if (childError is AppError) {
        childError = childError.cause;
      } else {
        break;
      }
    }

    return chain;
  }

  /// Checks wether [causeChain] contains any element of [T] type.
  ///
  /// If you didn't pass [T] then it will always return true in production.
  bool causedBy<T>() {
    assert(
      T != dynamic,
      'Tried to call AppError.causedBy<dynamic>(). This is likely a mistake '
      'and is therefore unsupported. If you want to check error that can '
      'be anything, consider changing `dynamic` to `Object` instead.',
    );

    return causeChain.any((element) => element is T);
  }

  /// The returned elements will be joined and pasted into result of [toString].
  ///
  /// When override this method call parent implementation like this:
  ///
  /// ```dart
  ///   @override
  ///   Map<String, Object?> describeDetails() => {
  ///      'response': response,
  ///      ...super.describeDetails(),
  ///    };
  /// ```
  @mustCallSuper
  Map<String, Object?> describeDetails() => {};

  @override
  String toString() {
    var result =
        '$runtimeType(message: $message, level: ${level.value} (${level.description}}, ';

    final details = describeDetails();
    if (details.isNotEmpty) {
      final detailsList = details.entries;
      final detailsListString = detailsList.map(
        (detail) => '${detail.key}: ${detail.value}',
      );
      result += '${detailsListString.join(', ')}, ';
    }

    result += 'cause: $cause, stackTrace: $stackTrace)';

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppError &&
        other.message == message &&
        other.cause == cause &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => message.hashCode ^ cause.hashCode ^ stackTrace.hashCode;
}
