import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthSessionRecoveryScreen extends StatelessWidget {
  const AuthSessionRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenSkeleton(
      enableBottomPlayer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.sessionRestoreRetryMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<AuthBloc>().add(
                  const AuthSessionRestoreRequested(),
                ),
                child: Text(context.l10n.retrySessionRestoreButton),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                child: Text(context.l10n.continueSignedOutButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
