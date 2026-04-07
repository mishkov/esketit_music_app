import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/ui/auth/sign_up_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _outlinedBorder = const OutlineInputBorder();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failure != current.failure,
      listener: _onAuthStateChanged,
      child: ScreenSkeleton(
        enableBottomPlayer: false,
        // TODO: translate all the strings.
        appBar: AppBar(title: const Text('Sign in')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: _outlinedBorder,
                              enabledBorder: _outlinedBorder,
                              focusedBorder: _outlinedBorder,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: _outlinedBorder,
                              enabledBorder: _outlinedBorder,
                              focusedBorder: _outlinedBorder,
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: state.isSubmitting ? null : _submit,
                            child: state.isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign in'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => _openSignUp(context),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TODO: better to move this validator to some shared class and domain layer.
  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your email';
    }
    if (!text.contains('@')) {
      return 'Enter a valid email';
    }

    return null;
  }

  // TODO: better to move this validator to some shared class and domain layer.
  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Enter your password';
    }

    return null;
  }

  String? _toFailureMessage(AppError? error) {
    if (error == null) {
      return null;
    }
    if (error is ForbiddenAppError) {
      return 'You do not have access to this action.';
    }
    if (error is UnauthorizedAppError) {
      return 'Your session expired. Please sign in again.';
    }
    if (error is HttpAppError) {
      return 'Request failed. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticated) {
      // TODO: make this navigation more universal so we don't accidentally navigate to some infinity-loading screen.
      Navigator.of(context).popUntil((route) => route.isFirst);

      return;
    }

    final failureMessage = _toFailureMessage(state.failure);
    if (failureMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));
  }
}
