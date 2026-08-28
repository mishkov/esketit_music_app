import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/player/playback_repeat_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlaybackRepeatButton extends StatelessWidget {
  const PlaybackRepeatButton({
    required this.playerState,
    this.enabled = true,
    super.key,
  });

  final PlayerState playerState;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final repeatMode = playerState.repeatMode;
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: switch (repeatMode) {
        PlaybackRepeatMode.off =>
          playerState.isAutoplayActive
              ? context.l10n.repeatTrackTooltip
              : context.l10n.repeatQueueTooltip,
        PlaybackRepeatMode.queue => context.l10n.repeatTrackTooltip,
        PlaybackRepeatMode.track => context.l10n.repeatOffTooltip,
      },
      onPressed: enabled
          ? () =>
                context.read<PlayerBloc>().add(const CycleRepeatModeRequested())
          : null,
      icon: Icon(
        repeatMode == PlaybackRepeatMode.track
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        color: repeatMode == PlaybackRepeatMode.off
            ? null
            : colorScheme.primary,
      ),
      iconSize: 32,
    );
  }
}
