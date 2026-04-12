import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/track_lyrics_screen.dart';
import 'package:esketit_music_app/use_case/lyrics/bloc/lyrics_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackLyricsSection extends StatefulWidget {
  const TrackLyricsSection({required this.trackId, super.key});

  final int trackId;

  @override
  State<TrackLyricsSection> createState() => _TrackLyricsSectionState();
}

class _TrackLyricsSectionState extends State<TrackLyricsSection> {
  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(covariant TrackLyricsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trackId != widget.trackId) {
      _loadLyrics();
    }
  }

  void _loadLyrics() {
    context.read<LyricsBloc>().add(LoadTrackLyrics(widget.trackId));
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.trackScreenLyricsSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _openFullscreenLyrics(context),
                  tooltip: context.l10n.trackScreenLyricsFullscreenTooltip,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300),
              child: BlocBuilder<LyricsBloc, LyricsState>(
                buildWhen: (previous, current) =>
                    previous.trackId != current.trackId ||
                    previous.lyrics != current.lyrics ||
                    previous.isLoading != current.isLoading ||
                    previous.loadFailed != current.loadFailed,
                builder: (context, state) {
                  if (state.trackId != widget.trackId) {
                    return Text(context.l10n.trackScreenLyricsNotAvailable);
                  }

                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.loadFailed) {
                    return Text(context.l10n.trackScreenLyricsLoadFailed);
                  }

                  return _buildLyricsContent(context, state.lyrics);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenLyrics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const TrackLyricsScreen()),
    );
  }

  Widget _buildLyricsContent(BuildContext context, TrackLyrics? lyrics) {
    if (lyrics == null) {
      return Text(context.l10n.trackScreenLyricsNotAvailable);
    }

    if (!lyrics.hasContent) {
      return Text(context.l10n.trackScreenLyricsNotAvailable);
    }

    return Text(
      lyrics.displayText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
      overflow: TextOverflow.ellipsis,
    );
  }
}
