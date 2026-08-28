import 'package:esketit_music_app/ui/player/playback_repeat_button.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';

class PlaybackSecondaryControlsRow extends StatelessWidget {
  const PlaybackSecondaryControlsRow({
    required this.playerState,
    this.enabled = true,
    super.key,
  });

  static const _invisibleButton = Visibility(
    visible: false,
    maintainAnimation: true,
    maintainSize: true,
    maintainState: true,
    child: IconButton(
      onPressed: null,
      icon: Icon(Icons.circle_outlined),
      iconSize: 32,
    ),
  );

  final PlayerState playerState;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: PlaybackRepeatButton(
              playerState: playerState,
              enabled: enabled,
            ),
          ),
        ),
        const Expanded(child: Center(child: _invisibleButton)),
        const Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _invisibleButton,
          ),
        ),
      ],
    );
  }
}
