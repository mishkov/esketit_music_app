import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/albums/album_summary_card.dart';
import 'package:esketit_music_app/ui/authors/author_desktop_layout.dart';
import 'package:esketit_music_app/ui/authors/author_mobile_layout.dart';
import 'package:esketit_music_app/ui/downloads/collection_download_button.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_collection_remove_button.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_tracks_section.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedAlbumDetailsScreen extends StatelessWidget {
  const DownloadedAlbumDetailsScreen({required this.albumId, super.key});

  final int albumId;

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
        final album = state.library.albums
            .where((album) => album.id == albumId)
            .firstOrNull;

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(album?.title ?? context.l10n.downloadedAlbumsTitle),
          ),
          body: switch (state.availability) {
            DownloadsAvailability.starting => const Center(
              child: CircularProgressIndicator(),
            ),
            DownloadsAvailability.unsupported => Center(
              child: Text(context.l10n.downloadsUnavailableMessage),
            ),
            DownloadsAvailability.ready when album == null => Center(
              child: Text(context.l10n.downloadedAlbumNotFound),
            ),
            DownloadsAvailability.ready => _buildContent(
              context,
              album!,
              _orderedTracks(album, state.library.tracks),
              selectedTrackExists,
              hasDownloadReference: state.library.albumDownloadIds.contains(
                album.id,
              ),
            ),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Album album,
    List<Track> tracks,
    bool selectedTrackExists, {
    required bool hasDownloadReference,
  }) {
    final summary = AlbumSummaryCard(
      album: album,
      downloadAction: hasDownloadReference
          ? DownloadedCollectionRemoveButton(
              kind: DownloadCollectionUiKind.album,
              onPressed: () => context.read<DownloadsBloc>().add(
                RemoveAlbumDownloadRequested(album.id),
              ),
            )
          : null,
    );
    final tracksSection = DownloadedTracksSection(
      tracks: tracks,
      emptyMessage: context.l10n.noDownloadedTracksInAlbum,
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

  List<Track> _orderedTracks(Album album, List<Track> downloadedTracks) {
    final albumTrackIds = album.trackIds.toSet();
    final candidates = downloadedTracks
        .where(
          (track) =>
              track.albumId == album.id || albumTrackIds.contains(track.id),
        )
        .toList(growable: false);
    final tracksById = {for (final track in candidates) track.id: track};
    final orderedTracks = album.trackIds
        .map((trackId) => tracksById[trackId])
        .nonNulls
        .toList();
    final orderedTrackIds = orderedTracks.map((track) => track.id).toSet();
    orderedTracks.addAll(
      candidates.where((track) => !orderedTrackIds.contains(track.id)),
    );

    return orderedTracks;
  }
}
