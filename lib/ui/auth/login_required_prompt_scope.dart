import 'package:flutter/material.dart';

class LoginRequiredPromptController extends ChangeNotifier {
  void show() {
    notifyListeners();
  }
}

class LoginRequiredPromptScope
    extends InheritedNotifier<LoginRequiredPromptController> {
  const LoginRequiredPromptScope({
    required LoginRequiredPromptController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LoginRequiredPromptController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LoginRequiredPromptScope>();
    assert(
      scope != null,
      'LoginRequiredPromptScope is missing in the widget tree.',
    );

    return scope!.notifier!;
  }
}
