import 'package:esketit_music_app/ui/home/home_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.restoring) {
          return const ScreenSkeleton(
            enableBottomPlayer: false,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
