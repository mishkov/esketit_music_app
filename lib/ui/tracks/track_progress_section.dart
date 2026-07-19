import 'package:esketit_music_app/ui/shared/animated_collapsible.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackProgressSection extends StatefulWidget {
  const TrackProgressSection({this.showTiming = true, super.key});

  final bool showTiming;

  @override
  State<TrackProgressSection> createState() => _TrackProgressSectionState();
}

class _TrackProgressSectionState extends State<TrackProgressSection> {
  Duration? _draggedPosition;
  PlayerBloc? _playerBloc;
  Stream<PlayerPlaybackProgress>? _playbackProgressStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final playerBloc = context.read<PlayerBloc>();
    if (_playerBloc == playerBloc) {
      return;
    }

    _playerBloc = playerBloc;
    _playbackProgressStream = playerBloc.playbackProgressStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerPlaybackProgress>(
      stream: _playbackProgressStream,
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
        final actualPosition = _normalizePosition(
          playbackProgress.position,
          playbackProgress.duration,
        );
        final duration = playbackProgress.duration;
        final position = _normalizePosition(
          _draggedPosition ?? actualPosition,
          duration,
        );
        final durationMilliseconds = duration.inMilliseconds;
        final sliderMax = durationMilliseconds > 0
            ? durationMilliseconds.toDouble()
            : 1.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 4,
                  disabledThumbRadius: 4,
                ),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                value: position.inMilliseconds
                    .clamp(0, sliderMax.toInt())
                    .toDouble(),
                max: sliderMax,
                onChanged: durationMilliseconds == 0
                    ? null
                    : (value) {
                        setState(() {
                          _draggedPosition = Duration(
                            milliseconds: value.round(),
                          );
                        });
                      },
                onChangeEnd: durationMilliseconds == 0
                    ? null
                    : (value) {
                        final seekPosition = Duration(
                          milliseconds: value.round(),
                        );

                        setState(() {
                          _draggedPosition = null;
                        });

                        context.read<PlayerBloc>().add(
                          SeekToPositionRequested(seekPosition),
                        );
                      },
              ),
            ),
            AnimatedCollapsible(
              visible: widget.showTiming,
              topPadding: 8,
              child: Row(
                children: [
                  Text(_formatDuration(position)),
                  const Spacer(),
                  Text(_formatDuration(duration)),
                ],
              ),
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
