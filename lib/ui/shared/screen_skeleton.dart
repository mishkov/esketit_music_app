import 'package:esketit_music_app/ui/auth/login_required_prompt_host.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.enableBottomPlayer = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool enableBottomPlayer;

  @override
  Widget build(BuildContext context) {
    Widget screenBody = body;

    if (enableBottomPlayer) {
      screenBody = BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return Stack(
            children: [
              body,
              if (state.selectedTrack != null)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: BottomPlayer(),
                ),
            ],
          );
        },
      );
    }

    return LoginRequiredPromptHost(
      child: Scaffold(
        appBar: appBar,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: screenBody,
      ),
    );
  }
}
