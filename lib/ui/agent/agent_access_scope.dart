import 'package:flutter/widgets.dart';

class AgentAccessScope extends InheritedWidget {
  const AgentAccessScope({
    required this.allowed,
    required super.child,
    super.key,
  });

  final bool allowed;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AgentAccessScope>()?.allowed ??
      false;

  @override
  bool updateShouldNotify(AgentAccessScope oldWidget) =>
      allowed != oldWidget.allowed;
}
