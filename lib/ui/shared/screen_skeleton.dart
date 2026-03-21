import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:flutter/material.dart';

class ScreenSkeleton extends StatelessWidget {
  const ScreenSkeleton({
    required this.body,
    super.key,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return LoginRequiredPromptHost(
      child: Scaffold(
        appBar: appBar,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: body,
      ),
    );
  }
}
