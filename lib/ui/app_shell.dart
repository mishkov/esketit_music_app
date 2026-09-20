import 'package:esketit_music_app/ui/home/home_screen.dart';
import 'package:esketit_music_app/ui/auth/auth_session_recovery_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    context.read<AuthBloc>().add(
      const AuthSessionRestoreRequested(showProgress: false),
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        if (state.status == AuthStatus.restoring) {
          return const ScreenSkeleton(
            enableBottomPlayer: false,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == AuthStatus.restorationFailed) {
          return const AuthSessionRecoveryScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
