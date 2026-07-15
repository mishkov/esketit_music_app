import 'dart:async';

import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/player/fullscreen_lyrics_panel.dart';
import 'package:esketit_music_app/ui/player/fullscreen_player_platform.dart';
import 'package:esketit_music_app/ui/player/fullscreen_track_presentation.dart';
import 'package:esketit_music_app/use_case/lyrics/bloc/lyrics_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({super.key});

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  static const _controlsIdleTimeout = Duration(seconds: 3);
  static const _layoutBreakpoint = 900.0;
  static const _contentMaxWidth = 1480.0;
  static const _artworkMaxSize = 460.0;

  Timer? _controlsHideTimer;
  bool _areControlsVisible = false;

  @override
  void initState() {
    super.initState();
    _loadLyricsForTrack(context.read<PlayerBloc>().state.selectedTrack?.id);
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    unawaited(exitAppFullscreen());
    super.dispose();
  }

  void _loadLyricsForTrack(int? trackId) {
    if (trackId == null) {
      return;
    }

    context.read<LyricsBloc>().add(LoadTrackLyrics(trackId));
  }

  void _handlePlayerStateChanged(BuildContext context, PlayerState state) {
    _loadLyricsForTrack(state.selectedTrack?.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onHover: (_) => _showControlsTemporarily(),
      child: BlocConsumer<PlayerBloc, PlayerState>(
        listenWhen: (previous, current) =>
            previous.selectedTrack?.id != current.selectedTrack?.id,
        listener: _handlePlayerStateChanged,
        buildWhen: (previous, current) =>
            previous.selectedTrack != current.selectedTrack ||
            previous.isPlaying != current.isPlaying ||
            previous.hasPreviousTrack != current.hasPreviousTrack ||
            previous.hasNextTrack != current.hasNextTrack,
        builder: (context, playerState) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Stack(
              children: [
                Positioned.fill(child: _buildBody(context, playerState)),
                Positioned(
                  top: 24,
                  right: 32,
                  child: SafeArea(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _areControlsVisible ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_areControlsVisible,
                        child: IconButton.filledTonal(
                          tooltip: context.l10n.fullscreenPlayerCloseTooltip,
                          onPressed: () => _close(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PlayerState playerState) {
    final selectedTrack = playerState.selectedTrack;
    if (selectedTrack == null) {
      return Center(
        child: Text(context.l10n.trackScreenNoTrackSelectedMessage),
      );
    }

    return BlocBuilder<LyricsBloc, LyricsState>(
      buildWhen: (previous, current) =>
          previous.trackId != current.trackId ||
          previous.lyrics != current.lyrics ||
          previous.isLoading != current.isLoading ||
          previous.loadFailed != current.loadFailed,
      builder: (context, lyricsState) {
        final lyrics = _effectiveLyrics(
          trackId: selectedTrack.id,
          lyricsState: lyricsState,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final useLyricsLayout =
                constraints.maxWidth >= _layoutBreakpoint && lyrics != null;

            if (useLyricsLayout) {
              return _buildLyricsLayout(
                context,
                selectedTrack,
                lyrics,
                playerState,
              );
            }

            return _buildArtworkOnlyLayout(context, selectedTrack, playerState);
          },
        );
      },
    );
  }

  Widget _buildLyricsLayout(
    BuildContext context,
    Track track,
    TrackLyrics lyrics,
    PlayerState playerState,
  ) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 72, 56, 56),
            child: Row(
              children: [
                Expanded(
                  child: FullscreenTrackPresentation(
                    areControlsVisible: _areControlsVisible,
                    playerState: playerState,
                    track: track,
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(flex: 2, child: FullscreenLyricsPanel(lyrics: lyrics)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkOnlyLayout(
    BuildContext context,
    Track track,
    PlayerState playerState,
  ) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _artworkMaxSize),
            child: FullscreenTrackPresentation(
              areControlsVisible: _areControlsVisible,
              playerState: playerState,
              track: track,
            ),
          ),
        ),
      ),
    );
  }

  TrackLyrics? _effectiveLyrics({
    required int trackId,
    required LyricsState lyricsState,
  }) {
    final lyrics = lyricsState.lyrics;
    if (lyricsState.trackId != trackId ||
        lyricsState.isLoading ||
        lyricsState.loadFailed ||
        lyrics == null ||
        !lyrics.hasContent) {
      return null;
    }

    return lyrics;
  }

  void _showControlsTemporarily() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(_controlsIdleTimeout, _hideControls);

    if (_areControlsVisible) {
      return;
    }

    setState(() {
      _areControlsVisible = true;
    });
  }

  void _hideControls() {
    if (!mounted || !_areControlsVisible) {
      return;
    }

    setState(() {
      _areControlsVisible = false;
    });
  }

  void _close(BuildContext context) {
    context.read<ErrorReporter>().addBreadcrumb(
      Breadcrumb(
        message: 'Close fullscreen player',
        category: Category.uiClick,
      ),
    );
    Navigator.of(context).pop();
  }
}
