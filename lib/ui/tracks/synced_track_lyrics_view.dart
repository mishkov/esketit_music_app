import 'dart:async';

import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncedTrackLyricsView extends StatefulWidget {
  const SyncedTrackLyricsView({required this.lyrics, super.key});

  final TrackLyrics lyrics;

  @override
  State<SyncedTrackLyricsView> createState() => _SyncedTrackLyricsViewState();
}

class _SyncedTrackLyricsViewState extends State<SyncedTrackLyricsView> {
  static const _activeLineAlignment = 0.35;
  static const _lineSwitchDuration = Duration(milliseconds: 300);
  static const _autoScrollResumeDelay = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _lineKeys = [];

  Timer? _autoScrollResumeTimer;
  StreamSubscription<PlayerPlaybackProgress>? _playbackProgressSubscription;
  int? _activeLineIndex;
  Duration _latestPlaybackPosition = Duration.zero;
  bool _isAutoScrollSuspended = false;
  bool _isProgrammaticScrollInProgress = false;

  @override
  void initState() {
    super.initState();
    _replaceLineKeys();
    _latestPlaybackPosition = context.read<PlayerBloc>().currentPosition;
    _activeLineIndex = widget.lyrics.syncedLineIndexAt(_latestPlaybackPosition);
    _scrollToActiveLine();
    _subscribeToPlaybackProgress();
  }

  @override
  void didUpdateWidget(covariant SyncedTrackLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lyrics != widget.lyrics) {
      _replaceLineKeys();
      _activeLineIndex = widget.lyrics.syncedLineIndexAt(
        _latestPlaybackPosition,
      );
      _scrollToActiveLine();
    }
  }

  @override
  void dispose() {
    _autoScrollResumeTimer?.cancel();
    _playbackProgressSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToPlaybackProgress() {
    final playerBloc = context.read<PlayerBloc>();
    _playbackProgressSubscription = playerBloc.playbackProgressStream.listen((
      playbackProgress,
    ) {
      _latestPlaybackPosition = playbackProgress.position;
      _updateActiveLine(_latestPlaybackPosition);
    });
  }

  void _updateActiveLine(Duration position) {
    final nextActiveLineIndex = widget.lyrics.syncedLineIndexAt(position);
    if (_activeLineIndex == nextActiveLineIndex) {
      return;
    }

    setState(() {
      _activeLineIndex = nextActiveLineIndex;
    });

    if (nextActiveLineIndex == null) {
      return;
    }

    _scrollToActiveLine();
  }

  void _replaceLineKeys() {
    _lineKeys
      ..clear()
      ..addAll(
        List<GlobalKey>.generate(
          widget.lyrics.lines.length,
          (index) => GlobalKey(debugLabel: 'synced-lyrics-line-$index'),
        ),
      );
  }

  void _scrollToActiveLine() {
    final activeLineIndex = _activeLineIndex;
    if (activeLineIndex == null || _isAutoScrollSuspended) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final lineContext = _lineKeys[activeLineIndex].currentContext;
      if (lineContext == null) {
        return;
      }

      _isProgrammaticScrollInProgress = true;
      Scrollable.ensureVisible(
        lineContext,
        alignment: _activeLineAlignment,
        duration: _lineSwitchDuration,
        curve: Curves.easeInOut,
      ).whenComplete(() {
        _isProgrammaticScrollInProgress = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 48,
        ).copyWith(bottom: 100),
        child: Column(
          children: [
            for (
              var index = 0;
              index < widget.lyrics.lines.length;
              index += 1
            ) ...[
              _buildLyricsLine(context: context, theme: theme, index: index),
              if (index + 1 < widget.lyrics.lines.length)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isProgrammaticScrollInProgress) {
      return false;
    }

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _suspendAutoScroll();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _suspendAutoScroll();
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      _suspendAutoScroll();
    } else if (notification is ScrollEndNotification &&
        _isAutoScrollSuspended) {
      _restartAutoScrollResumeTimer();
    }

    return false;
  }

  void _suspendAutoScroll() {
    _isAutoScrollSuspended = true;
    _restartAutoScrollResumeTimer();
  }

  void _restartAutoScrollResumeTimer() {
    _autoScrollResumeTimer?.cancel();
    _autoScrollResumeTimer = Timer(
      _autoScrollResumeDelay,
      _resumeAutoScrollAfterUserIdle,
    );
  }

  void _resumeAutoScrollAfterUserIdle() {
    if (!mounted) {
      return;
    }

    _isAutoScrollSuspended = false;
    _scrollToActiveLine();
  }

  Widget _buildLyricsLine({
    required BuildContext context,
    required ThemeData theme,
    required int index,
  }) {
    final line = widget.lyrics.lines[index];
    final lineText = line.text.trim();
    final isActiveLine = index == _activeLineIndex;
    final textStyle =
        theme.textTheme.titleLarge?.copyWith(height: 1.35) ??
        const TextStyle(fontSize: 24);

    return AnimatedOpacity(
      key: _lineKeys[index],
      duration: _lineSwitchDuration,
      opacity: isActiveLine ? 1 : 0.3,
      child: InkWell(
        onTap: _createLyricsLineTapCallback(line),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedScale(
            duration: _lineSwitchDuration,
            curve: Curves.easeInOut,
            scale: isActiveLine ? 1.3 : 1,
            child: Text(
              lineText,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback _createLyricsLineTapCallback(SyncedTrackLyricsLine line) {
    return () => _seekToLineStart(line);
  }

  void _seekToLineStart(SyncedTrackLyricsLine line) {
    context.read<PlayerBloc>().add(
      SeekToPositionRequested(Duration(milliseconds: line.startMs)),
    );
  }
}
