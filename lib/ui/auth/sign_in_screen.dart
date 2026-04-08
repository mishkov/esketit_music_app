import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
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
    final l10n = context.l10n;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failure != current.failure,
      listener: _onAuthStateChanged,
      child: ScreenSkeleton(
        enableBottomPlayer: false,
        appBar: AppBar(title: Text(l10n.signInTitle)),
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
                              labelText: l10n.emailLabel,
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
                              labelText: l10n.passwordLabel,
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
                                : Text(l10n.signInButton),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => _openSignUp(context),
                            child: Text(l10n.createAccountLink),
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
    final l10n = context.l10n;
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return l10n.enterYourEmail;
    }
    if (!text.contains('@')) {
      return l10n.enterValidEmail;
    }

    return null;
  }

  // TODO: better to move this validator to some shared class and domain layer.
  String? _validatePassword(String? value) {
    final l10n = context.l10n;
    final text = value ?? '';
    if (text.isEmpty) {
      return l10n.enterYourPassword;
    }

    return null;
  }

  String? _toFailureMessage(AppError? error) {
    final l10n = context.l10n;

    if (error == null) {
      return null;
    }
    if (error is ForbiddenAppError) {
      return l10n.forbiddenActionMessage;
    }
    if (error is UnauthorizedAppError) {
      return l10n.sessionExpiredMessage;
    }
    if (error is HttpAppError) {
      return l10n.requestFailedMessage;
    }

    return l10n.unknownErrorMessage;
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
