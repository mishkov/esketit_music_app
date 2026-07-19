import 'dart:async';

import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncedTrackLyricsView extends StatefulWidget {
  const SyncedTrackLyricsView({
    required this.lyrics,
    this.activeLineAlignment = 0.35,
    this.activeLineScale = 1.3,
    this.inactiveLineOpacity = 0.3,
    this.lineSpacing = 10,
    this.padding = const EdgeInsets.fromLTRB(48, 24, 48, 100),
    this.showLeadingBeatIndicator = false,
    this.textStyle,
    super.key,
  });

  final TrackLyrics lyrics;
  final double activeLineAlignment;
  final double activeLineScale;
  final double inactiveLineOpacity;
  final double lineSpacing;
  final EdgeInsetsGeometry padding;
  final bool showLeadingBeatIndicator;
  final TextStyle? textStyle;

  @override
  State<SyncedTrackLyricsView> createState() => _SyncedTrackLyricsViewState();
}

class _SyncedTrackLyricsViewState extends State<SyncedTrackLyricsView> {
  static const _beatIndicatorStepDuration = Duration(milliseconds: 750);
  static const _lineSwitchDuration = Duration(milliseconds: 300);
  static const _autoScrollResumeDelay = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _lineKeys = [];

  Timer? _autoScrollResumeTimer;
  Timer? _beatIndicatorTimer;
  StreamSubscription<PlayerPlaybackProgress>? _playbackProgressSubscription;
  int _activeBeatIndicatorDotIndex = 0;
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
    _updateBeatIndicatorTimer();
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
      _updateBeatIndicatorTimer();
    }
  }

  @override
  void dispose() {
    _autoScrollResumeTimer?.cancel();
    _beatIndicatorTimer?.cancel();
    _playbackProgressSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToPlaybackProgress() {
    final playerBloc = context.read<PlayerBloc>();
    _playbackProgressSubscription = playerBloc.playbackProgressStream.listen((
      playbackProgress,
    ) {
      _updateActiveLine(playbackProgress.position);
    });
  }

  void _updateActiveLine(Duration position) {
    final wasLeadingBeatIndicatorVisible = _shouldShowLeadingBeatIndicator;
    _latestPlaybackPosition = position;
    final nextActiveLineIndex = widget.lyrics.syncedLineIndexAt(position);
    final shouldShowLeadingBeatIndicator = _shouldShowLeadingBeatIndicator;
    if (_activeLineIndex == nextActiveLineIndex &&
        wasLeadingBeatIndicatorVisible == shouldShowLeadingBeatIndicator) {
      return;
    }

    setState(() {
      _activeLineIndex = nextActiveLineIndex;
    });
    _updateBeatIndicatorTimer();

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
        alignment: widget.activeLineAlignment,
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
        padding: widget.padding,
        child: Column(
          children: [
            if (widget.showLeadingBeatIndicator)
              _buildAnimatedLeadingBeatIndicator(context),
            for (
              var index = 0;
              index < widget.lyrics.lines.length;
              index += 1
            ) ...[
              _buildLyricsLine(context: context, theme: theme, index: index),
              if (index + 1 < widget.lyrics.lines.length)
                SizedBox(height: widget.lineSpacing),
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
        widget.textStyle ??
        theme.textTheme.titleLarge?.copyWith(height: 1.35) ??
        const TextStyle(fontSize: 24);

    return AnimatedOpacity(
      key: _lineKeys[index],
      duration: _lineSwitchDuration,
      opacity: isActiveLine ? 1 : widget.inactiveLineOpacity,
      child: InkWell(
        onTap: _createLyricsLineTapCallback(line),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedScale(
            duration: _lineSwitchDuration,
            curve: Curves.easeInOut,
            scale: isActiveLine ? widget.activeLineScale : 1,
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

  bool get _shouldShowLeadingBeatIndicator {
    return widget.showLeadingBeatIndicator &&
        _activeLineIndex == null &&
        _isBeforeFirstLine;
  }

  bool get _isBeforeFirstLine {
    if (widget.lyrics.lines.isEmpty) {
      return false;
    }

    return _latestPlaybackPosition.inMilliseconds <
        widget.lyrics.lines.first.startMs;
  }

  Widget _buildAnimatedLeadingBeatIndicator(BuildContext context) {
    final isVisible = _shouldShowLeadingBeatIndicator;

    return AnimatedSize(
      duration: _lineSwitchDuration,
      curve: Curves.easeInOut,
      child: ClipRect(
        child: AnimatedAlign(
          duration: _lineSwitchDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          heightFactor: isVisible ? 1.0 : 0.0,
          child: AnimatedOpacity(
            duration: _lineSwitchDuration,
            opacity: isVisible ? 1 : 0,
            child: Column(
              children: [
                _buildLeadingBeatIndicator(context),
                SizedBox(height: widget.lineSpacing * 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingBeatIndicator(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 34,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 4; index += 1) ...[
              _buildBeatIndicatorDot(
                color: color,
                isActive: index == _activeBeatIndicatorDotIndex,
              ),
              if (index < 3) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBeatIndicatorDot({
    required Color color,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: _lineSwitchDuration,
      curve: Curves.easeInOut,
      width: isActive ? 34 : 28,
      height: isActive ? 34 : 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.72 : 0.36),
        shape: BoxShape.circle,
      ),
    );
  }

  void _updateBeatIndicatorTimer() {
    if (!_shouldShowLeadingBeatIndicator) {
      _beatIndicatorTimer?.cancel();
      _beatIndicatorTimer = null;

      return;
    }

    if (_beatIndicatorTimer != null) {
      return;
    }

    _beatIndicatorTimer = Timer.periodic(
      _beatIndicatorStepDuration,
      (_) => _advanceBeatIndicator(),
    );
  }

  void _advanceBeatIndicator() {
    if (!mounted || !_shouldShowLeadingBeatIndicator) {
      _updateBeatIndicatorTimer();

      return;
    }

    setState(() {
      _activeBeatIndicatorDotIndex = (_activeBeatIndicatorDotIndex + 1) % 4;
    });
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
