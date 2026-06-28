import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/single_line_overflow_marquee_text.dart';
import 'package:esketit_music_app/ui/tracks/author_picker_sheet.dart';
import 'package:esketit_music_app/ui/tracks/track_controls_row.dart';
import 'package:esketit_music_app/ui/tracks/track_lyrics_section.dart';
import 'package:esketit_music_app/ui/tracks/track_progress_section.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';

class TrackScreenBody extends StatelessWidget {
  const TrackScreenBody({required this.track, required this.state, super.key});

  final Track track;
  final PlayerState state;

  static const _desktopLayoutBreakpoint = 900.0;
  static const _contentMaxWidth = 1200.0;
  static const _desktopLyricsMaxHeight = 560.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artworkUrl = _trackImageUrl(track);

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useDesktopLayout =
              constraints.maxWidth >= _desktopLayoutBreakpoint;
          final content = useDesktopLayout
              ? _buildDesktopLayout(context, theme, artworkUrl)
              : _buildMobileLayout(context, theme, artworkUrl);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: content,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    String? artworkUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildArtwork(
          artworkUrl,
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
        ),
        _buildTrackTitleBlock(
          context,
          theme,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        const TrackProgressSection(),
        const SizedBox(height: 24),
        TrackControlsRow(state: state, track: track),
        const SizedBox(height: 24),
        TrackLyricsSection(trackId: track.id),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    String? artworkUrl,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildDesktopPlaybackPanel(context, theme, artworkUrl),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: TrackLyricsSection(
            trackId: track.id,
            maxHeight: _desktopLyricsMaxHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPlaybackPanel(
    BuildContext context,
    ThemeData theme,
    String? artworkUrl,
  ) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildArtwork(artworkUrl, borderRadius: 20),
            const SizedBox(height: 16),
            _buildTrackTitleBlock(context, theme),
            const SizedBox(height: 12),
            const TrackProgressSection(),
            const SizedBox(height: 24),
            TrackControlsRow(state: state, track: track),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(
    String? artworkUrl, {
    required double borderRadius,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Center(
      child: Padding(
        padding: padding,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: RemoteImage(
              imageUrl: artworkUrl,
              icon: Icons.music_note_rounded,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTitleBlock(
    BuildContext context,
    ThemeData theme, {
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleLineOverflowMarqueeText(
              text: track.name,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: track.authors.isEmpty
                  ? null
                  : () => openAuthorSelection(context, track.authors),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _authorsLabel(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: track.authors.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _authorsLabel(BuildContext context) {
    final joinedAuthors = track.authors
        .map((author) => author.currentName)
        .where((authorName) => authorName.isNotEmpty)
        .join(', ');

    if (joinedAuthors.isNotEmpty) {
      return joinedAuthors;
    }

    return context.l10n.bottomPlayerUnknownArtist;
  }

  String? _trackImageUrl(Track track) {
    final image = track.image;
    if (image is! HttpFile) {
      return null;
    }

    final imageUrl = image.uri.toString();

    return imageUrl.isEmpty ? null : imageUrl;
  }
}
