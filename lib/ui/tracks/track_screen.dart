import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/author_picker_sheet.dart';
import 'package:esketit_music_app/ui/tracks/show_add_to_playlists_sheet.dart';
import 'package:esketit_music_app/ui/tracks/track_screen_body.dart';
import 'package:esketit_music_app/ui/tracks/track_routes.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({this.track, super.key});

  final Track? track;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack ||
          previous.isPlaying != current.isPlaying ||
          previous.hasPreviousTrack != current.hasPreviousTrack ||
          previous.hasNextTrack != current.hasNextTrack,
      builder: (context, state) {
        final displayedTrack = track ?? state.selectedTrack;
        final authors = displayedTrack?.authors ?? const <Author>[];
        final album = displayedTrack == null
            ? null
            : _albumForTrack(context.read<CatalogBloc>().state, displayedTrack);
        final hasMenuActions =
            displayedTrack != null || album != null || authors.isNotEmpty;

        return ScreenSkeleton(
          enableBottomPlayer: false,
          appBar: AppBar(
            title: Text(track?.name ?? context.l10n.trackScreenNowPlayingLabel),
            centerTitle: true,
            actions: [
              if (displayedTrack != null)
                IconButton(
                  tooltip: context.l10n.copyTrackLinkTooltip,
                  onPressed: () => _copyTrackLink(context, displayedTrack),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              PopupMenuButton<_TrackScreenMenuAction>(
                enabled: hasMenuActions,
                onSelected: (action) => _onMenuActionSelected(
                  context,
                  action,
                  displayedTrack,
                  album,
                  authors,
                ),
                itemBuilder: (context) => _buildTrackScreenMenuItems(
                  context,
                  displayedTrack,
                  album,
                  authors,
                ),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: displayedTrack == null
              ? Center(
                  child: Text(context.l10n.trackScreenNoTrackSelectedMessage),
                )
              : TrackScreenBody(track: displayedTrack, state: state),
        );
      },
    );
  }

  Future<void> _copyTrackLink(BuildContext context, Track track) async {
    unawaited(
      context.read<ErrorReporter>().addBreadcrumb(
        Breadcrumb(
          message: 'Copy track link',
          category: Category.uiClick,
          data: {'trackId': track.id},
        ),
      ),
    );

    await Clipboard.setData(
      ClipboardData(text: shareableTrackUri(track.id).toString()),
    );
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.trackLinkCopied)));
  }

  void _onMenuActionSelected(
    BuildContext context,
    _TrackScreenMenuAction action,
    Track? track,
    Album? album,
    List<Author> authors,
  ) async {
    switch (action) {
      case _TrackScreenMenuAction.addToPlaylists:
        if (track != null) {
          await showAddToPlaylistsSheet(context: context, track: track);
        }
      case _TrackScreenMenuAction.goToAlbum:
        if (album != null) {
          openAlbumDetails(context, album);
        }
      case _TrackScreenMenuAction.goToAuthor:
        await openAuthorSelection(context, authors);
    }
  }

  List<PopupMenuEntry<_TrackScreenMenuAction>> _buildTrackScreenMenuItems(
    BuildContext context,
    Track? track,
    Album? album,
    List<Author> authors,
  ) {
    return [
      if (track != null)
        PopupMenuItem<_TrackScreenMenuAction>(
          value: _TrackScreenMenuAction.addToPlaylists,
          child: Text(context.l10n.addToPlaylistsTooltip),
        ),
      if (album != null)
        PopupMenuItem<_TrackScreenMenuAction>(
          value: _TrackScreenMenuAction.goToAlbum,
          child: Text(context.l10n.trackScreenGoToAlbumAction),
        ),
      if (authors.isNotEmpty)
        PopupMenuItem<_TrackScreenMenuAction>(
          value: _TrackScreenMenuAction.goToAuthor,
          child: Text(context.l10n.trackScreenGoToAuthorAction),
        ),
    ];
  }

  Album? _albumForTrack(CatalogState catalogState, Track track) {
    for (final albums in catalogState.albumsByAuthorId.values) {
      for (final album in albums) {
        if (album.trackIds.contains(track.id)) {
          return album;
        }
      }
    }

    final searchResults = catalogState.searchResults;
    if (searchResults == null) {
      return null;
    }

    for (final searchResult in searchResults.items) {
      final album = searchResult.album;
      if (album != null && album.trackIds.contains(track.id)) {
        return album;
      }
    }

    return null;
  }
}

enum _TrackScreenMenuAction { addToPlaylists, goToAlbum, goToAuthor }
