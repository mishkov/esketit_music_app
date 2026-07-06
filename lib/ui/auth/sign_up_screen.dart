import 'package:esketit_music_app/domain/auth/auth_credentials_validator.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
        appBar: AppBar(title: Text(l10n.signUpTitle)),
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
                              helperText: l10n.passwordHelperText,
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
                                : Text(l10n.createAccountButton),
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

  String? _validateEmail(String? value) {
    final l10n = context.l10n;
    final error = AuthCredentialsValidator.validateEmail(value);

    return switch (error) {
      EmailValidationError.empty => l10n.enterYourEmail,
      EmailValidationError.invalid => l10n.enterValidEmail,
      null => null,
    };
  }

  String? _validatePassword(String? value) {
    final l10n = context.l10n;

    return switch (AuthCredentialsValidator.validateSignUpPassword(value)) {
      PasswordValidationError.empty => l10n.enterYourPassword,
      PasswordValidationError.tooShort => l10n.passwordMinLength,
      null => null,
    };
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
      AuthSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticated) {
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
}
