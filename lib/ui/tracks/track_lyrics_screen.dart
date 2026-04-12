import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/synced_track_lyrics_view.dart';
import 'package:esketit_music_app/use_case/lyrics/bloc/lyrics_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackLyricsScreen extends StatefulWidget {
  const TrackLyricsScreen({super.key});

  @override
  State<TrackLyricsScreen> createState() => _TrackLyricsScreenState();
}

class _TrackLyricsScreenState extends State<TrackLyricsScreen> {
  @override
  void initState() {
    super.initState();
    _loadLyricsForTrack(context.read<PlayerBloc>().state.selectedTrack?.id);
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
    return BlocConsumer<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) =>
          previous.selectedTrack?.id != current.selectedTrack?.id,
      listener: _handlePlayerStateChanged,
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final selectedTrack = playerState.selectedTrack;

        return ScreenSkeleton(
          appBar: AppBar(title: Text(context.l10n.trackLyricsScreenTitle)),
          body: BlocBuilder<LyricsBloc, LyricsState>(
            buildWhen: (previous, current) =>
                previous.trackId != current.trackId ||
                previous.lyrics != current.lyrics ||
                previous.isLoading != current.isLoading ||
                previous.loadFailed != current.loadFailed,
            builder: (context, lyricsState) {
              if (selectedTrack == null) {
                return Center(
                  child: Text(context.l10n.trackScreenNoTrackSelectedMessage),
                );
              }

              if (lyricsState.trackId != selectedTrack.id ||
                  lyricsState.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (lyricsState.loadFailed) {
                return Center(
                  child: Text(context.l10n.trackScreenLyricsLoadFailed),
                );
              }

              return _buildLyricsBody(context, lyricsState.lyrics);
            },
          ),
        );
      },
    );
  }

  Widget _buildLyricsBody(BuildContext context, TrackLyrics? lyrics) {
    if (lyrics == null || !lyrics.hasContent) {
      return Center(child: Text(context.l10n.trackScreenLyricsNotAvailable));
    }

    if (lyrics.type == TrackLyricsType.synced && lyrics.lines.isNotEmpty) {
      return SyncedTrackLyricsView(lyrics: lyrics);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        lyrics.displayText,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.5),
      ),
    );
  }
}
