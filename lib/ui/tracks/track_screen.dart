import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen_helpers.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/author_picker_sheet.dart';
import 'package:esketit_music_app/ui/tracks/track_screen_body.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack ||
          previous.isPlaying != current.isPlaying ||
          previous.hasPreviousTrack != current.hasPreviousTrack ||
          previous.hasNextTrack != current.hasNextTrack,
      builder: (context, state) {
        final selectedTrack = state.selectedTrack;
        final authors = selectedTrack?.authors ?? const <Author>[];
        final album = selectedTrack == null
            ? null
            : _albumForTrack(context.read<CatalogBloc>().state, selectedTrack);
        final hasMenuActions = album != null || authors.isNotEmpty;

        return ScreenSkeleton(
          enableBottomPlayer: false,
          appBar: AppBar(
            title: Text(context.l10n.trackScreenNowPlayingLabel),
            centerTitle: true,
            actions: [
              PopupMenuButton<_TrackScreenMenuAction>(
                enabled: hasMenuActions,
                onSelected: (action) =>
                    _onMenuActionSelected(context, action, album, authors),
                itemBuilder: (context) =>
                    _buildTrackScreenMenuItems(context, album, authors),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: selectedTrack == null
              ? Center(
                  child: Text(context.l10n.trackScreenNoTrackSelectedMessage),
                )
              : TrackScreenBody(track: selectedTrack, state: state),
        );
      },
    );
  }

  void _onMenuActionSelected(
    BuildContext context,
    _TrackScreenMenuAction action,
    Album? album,
    List<Author> authors,
  ) async {
    if (action == _TrackScreenMenuAction.goToAlbum && album != null) {
      openAlbumDetails(context, album);
    }
    if (action == _TrackScreenMenuAction.goToAuthor) {
      await openAuthorSelection(context, authors);
    }
  }

  List<PopupMenuEntry<_TrackScreenMenuAction>> _buildTrackScreenMenuItems(
    BuildContext context,
    Album? album,
    List<Author> authors,
  ) {
    return [
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

enum _TrackScreenMenuAction { goToAlbum, goToAuthor }
