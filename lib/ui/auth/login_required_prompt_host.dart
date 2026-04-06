import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/auth/show_login_required_dialog.dart';
import 'package:esketit_music_app/ui/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';

class LoginRequiredPromptHost extends StatefulWidget {
  const LoginRequiredPromptHost({required this.child, super.key});

  final Widget child;

  @override
  State<LoginRequiredPromptHost> createState() =>
      _LoginRequiredPromptHostState();
}

class _LoginRequiredPromptHostState extends State<LoginRequiredPromptHost> {
  final LoginRequiredPromptController _controller =
      LoginRequiredPromptController();
  bool _isShowingPrompt = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPromptRequested);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onPromptRequested)
      ..dispose();
    super.dispose();
  }

  Future<void> _onPromptRequested() async {
    if (_isShowingPrompt || !mounted) {
      return;
    }

    _isShowingPrompt = true;

    try {
      final shouldOpenLogin = await showLoginRequiredDialog(context);
      if (mounted && shouldOpenLogin == true) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SignInScreen()));
      }
    } finally {
      _isShowingPrompt = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginRequiredPromptScope(
      controller: _controller,
      child: widget.child,
    );
  }
}
