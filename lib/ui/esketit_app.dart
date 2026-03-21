import 'package:esketit_music_app/ui/home/home_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EsketitApp extends StatelessWidget {
  const EsketitApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Esketit Music',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.restoring) {
          return const ScreenSkeleton(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
