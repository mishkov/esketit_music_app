import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackProgressSection extends StatelessWidget {
  const TrackProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    return StreamBuilder<PlayerPlaybackProgress>(
      stream: playerBloc.playbackProgressStream,
      initialData: const PlayerPlaybackProgress(
        position: Duration.zero,
        duration: Duration.zero,
      ),
      builder: (context, snapshot) {
        final playbackProgress =
            snapshot.data ??
            const PlayerPlaybackProgress(
              position: Duration.zero,
              duration: Duration.zero,
            );
        final position = _normalizePosition(
          playbackProgress.position,
          playbackProgress.duration,
        );
        final duration = playbackProgress.duration;
        final durationMilliseconds = duration.inMilliseconds;
        final sliderMax = durationMilliseconds > 0
            ? durationMilliseconds.toDouble()
            : 1.0;

        return Column(
          children: [
            Slider(
              padding: EdgeInsets.zero,
              value: position.inMilliseconds
                  .clamp(0, sliderMax.toInt())
                  .toDouble(),
              max: sliderMax,
              onChanged: durationMilliseconds == 0 ? null : (_) {},
              onChangeEnd: durationMilliseconds == 0
                  ? null
                  : (value) {
                      context.read<PlayerBloc>().add(
                        SeekToPositionRequested(
                          Duration(milliseconds: value.round()),
                        ),
                      );
                    },
            ),
            Row(
              children: [
                Text(_formatDuration(position)),
                const Spacer(),
                Text(_formatDuration(duration)),
              ],
            ),
          ],
        );
      },
    );
  }

  Duration _normalizePosition(Duration position, Duration duration) {
    if (duration == Duration.zero) {
      return position < Duration.zero ? Duration.zero : position;
    }

    if (position < Duration.zero) {
      return Duration.zero;
    }
    if (position > duration) {
      return duration;
    }

    return position;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
