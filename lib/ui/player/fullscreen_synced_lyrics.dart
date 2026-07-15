import 'dart:async';

import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullscreenSyncedLyrics extends StatefulWidget {
  const FullscreenSyncedLyrics({required this.lyrics, super.key});

  final TrackLyrics lyrics;

  @override
  State<FullscreenSyncedLyrics> createState() => _FullscreenSyncedLyricsState();
}

class _FullscreenSyncedLyricsState extends State<FullscreenSyncedLyrics> {
  static const _lineSwitchDuration = Duration(milliseconds: 300);

  StreamSubscription<PlayerPlaybackProgress>? _playbackProgressSubscription;
  int? _activeLineIndex;

  @override
  void initState() {
    super.initState();
    _activeLineIndex = widget.lyrics.syncedLineIndexAt(
      context.read<PlayerBloc>().currentPosition,
    );
    _subscribeToPlaybackProgress();
  }

  @override
  void didUpdateWidget(covariant FullscreenSyncedLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lyrics != widget.lyrics) {
      _activeLineIndex = widget.lyrics.syncedLineIndexAt(
        context.read<PlayerBloc>().currentPosition,
      );
    }
  }

  @override
  void dispose() {
    _playbackProgressSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToPlaybackProgress() {
    _playbackProgressSubscription = context
        .read<PlayerBloc>()
        .playbackProgressStream
        .listen((playbackProgress) {
          final nextActiveLineIndex = widget.lyrics.syncedLineIndexAt(
            playbackProgress.position,
          );
          if (nextActiveLineIndex == _activeLineIndex) {
            return;
          }

          setState(() {
            _activeLineIndex = nextActiveLineIndex;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final visibleLineIndexes = _visibleLineIndexes();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBeatDots(context),
          const SizedBox(height: 92),
          for (final lineIndex in visibleLineIndexes) ...[
            _buildLine(context, lineIndex),
            if (lineIndex != visibleLineIndexes.last)
              const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildBeatDots(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 4; index += 1) ...[
          AnimatedContainer(
            duration: _lineSwitchDuration,
            width: index == 0 ? 34 : 28,
            height: index == 0 ? 34 : 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: index == 0 ? 0.72 : 0.36),
              shape: BoxShape.circle,
            ),
          ),
          if (index < 3) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildLine(BuildContext context, int lineIndex) {
    final theme = Theme.of(context);
    final line = widget.lyrics.lines[lineIndex];
    final lineText = line.text.trim();
    final isActiveLine = lineIndex == _currentLineIndex;

    return AnimatedOpacity(
      duration: _lineSwitchDuration,
      opacity: isActiveLine ? 1 : 0.36,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _seekToLineStart(line),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedScale(
            duration: _lineSwitchDuration,
            curve: Curves.easeInOut,
            scale: isActiveLine ? 1.08 : 1,
            child: Text(
              lineText,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  List<int> _visibleLineIndexes() {
    final currentLineIndex = _currentLineIndex;
    final indexes = <int>[];

    for (
      var index = currentLineIndex - 1;
      index <= currentLineIndex + 1;
      index += 1
    ) {
      if (index >= 0 && index < widget.lyrics.lines.length) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  int get _currentLineIndex {
    final activeLineIndex = _activeLineIndex;
    if (activeLineIndex != null) {
      return activeLineIndex;
    }

    return 0;
  }

  void _seekToLineStart(SyncedTrackLyricsLine line) {
    context.read<PlayerBloc>().add(
      SeekToPositionRequested(Duration(milliseconds: line.startMs)),
    );
  }
}
