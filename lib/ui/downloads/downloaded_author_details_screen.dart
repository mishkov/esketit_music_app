import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/authors/author_desktop_layout.dart';
import 'package:esketit_music_app/ui/authors/author_mobile_layout.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_author_summary_card.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_tracks_section.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedAuthorDetailsScreen extends StatelessWidget {
  const DownloadedAuthorDetailsScreen({required this.authorId, super.key});

  final int authorId;

  static const _desktopLayoutBreakpoint = 900.0;
  static const _contentMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return BlocBuilder<DownloadsBloc, DownloadsState>(
      buildWhen: (previous, current) =>
          previous.availability != current.availability ||
          previous.library != current.library,
      builder: (context, state) {
        final author = state.library.authors
            .where((author) => author.id == authorId)
            .firstOrNull;

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(
              author?.currentName ?? context.l10n.downloadedAuthorsTitle,
            ),
          ),
          body: switch (state.availability) {
            DownloadsAvailability.starting => const Center(
              child: CircularProgressIndicator(),
            ),
            DownloadsAvailability.unsupported => Center(
              child: Text(context.l10n.downloadsUnavailableMessage),
            ),
            DownloadsAvailability.ready when author == null => Center(
              child: Text(context.l10n.downloadedAuthorNotFound),
            ),
            DownloadsAvailability.ready => _buildContent(
              context,
              author!,
              state,
              selectedTrackExists,
            ),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Author author,
    DownloadsState state,
    bool selectedTrackExists,
  ) {
    final tracks = state.library.tracks
        .where(
          (track) =>
              track.authors.any((trackAuthor) => trackAuthor.id == authorId),
        )
        .toList(growable: false);
    final summary = DownloadedAuthorSummaryCard(author: author);
    final tracksSection = DownloadedTracksSection(
      tracks: tracks,
      emptyMessage: context.l10n.noDownloadedTracksForAuthor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= _desktopLayoutBreakpoint
            ? AuthorDesktopLayout(
                summary: summary,
                albumsSection: tracksSection,
              )
            : AuthorMobileLayout(
                summary: summary,
                albumsSection: tracksSection,
              );

        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            selectedTrackExists ? 100 : 16,
          ),
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
    );
  }
}
