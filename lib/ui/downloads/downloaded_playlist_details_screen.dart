import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/collection_download_button.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_collection_remove_button.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_playlist_header.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_track_card.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedPlaylistDetailsScreen extends StatefulWidget {
  const DownloadedPlaylistDetailsScreen({required this.playlistId, super.key});

  final int playlistId;

  @override
  State<DownloadedPlaylistDetailsScreen> createState() =>
      _DownloadedPlaylistDetailsScreenState();
}

class _DownloadedPlaylistDetailsScreenState
    extends State<DownloadedPlaylistDetailsScreen> {
  bool _hasRequestedTracks = false;
  int? _operationErrorSerialAtRequest;

  @override
  void initState() {
    super.initState();
    _loadTracksIfReady();
  }

  @override
  void didUpdateWidget(DownloadedPlaylistDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _hasRequestedTracks = false;
      _operationErrorSerialAtRequest = null;
      _loadTracksIfReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return BlocConsumer<DownloadsBloc, DownloadsState>(
      listenWhen: (previous, current) =>
          previous.availability != current.availability,
      listener: (context, state) => _loadTracksIfReady(),
      buildWhen: (previous, current) =>
          previous.availability != current.availability ||
          previous.library.playlists != current.library.playlists ||
          previous.library.playlistDownloadIds !=
              current.library.playlistDownloadIds ||
          previous.downloadedPlaylistTracks[widget.playlistId] !=
              current.downloadedPlaylistTracks[widget.playlistId] ||
          previous.loadingDownloadedPlaylistIds.contains(widget.playlistId) !=
              current.loadingDownloadedPlaylistIds.contains(
                widget.playlistId,
              ) ||
          previous.operationErrorSerial != current.operationErrorSerial,
      builder: (context, state) {
        final playlist = state.library.playlists
            .where((playlist) => playlist.id == widget.playlistId)
            .firstOrNull;

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(
              playlist?.name ?? context.l10n.downloadedPlaylistsTitle,
            ),
          ),
          body: _buildBody(context, state, playlist, selectedTrackExists),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DownloadsState state,
    Playlist? playlist,
    bool selectedTrackExists,
  ) {
    if (state.availability == DownloadsAvailability.starting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.isSupported) {
      return Center(child: Text(context.l10n.downloadsUnavailableMessage));
    }
    if (playlist == null) {
      return Center(child: Text(context.l10n.downloadedPlaylistNotFound));
    }

    final tracks = state.downloadedPlaylistTracks[widget.playlistId];
    if (tracks == null) {
      final requestFailed =
          _operationErrorSerialAtRequest != null &&
          state.operationErrorSerial > _operationErrorSerialAtRequest! &&
          !state.loadingDownloadedPlaylistIds.contains(widget.playlistId);
      if (requestFailed) {
        return Center(child: Text(context.l10n.downloadedPlaylistLoadFailed));
      }

      return const Center(child: CircularProgressIndicator());
    }

    final queue = downloadedPlaybackQueue(tracks);

    return Padding(
      padding: EdgeInsets.only(bottom: selectedTrackExists ? 100 : 0),
      child: Column(
        children: [
          DownloadedPlaylistHeader(
            playlist: playlist,
            downloadedTrackCount: tracks.length,
            downloadAction:
                state.library.playlistDownloadIds.contains(playlist.id)
                ? DownloadedCollectionRemoveButton(
                    kind: DownloadCollectionUiKind.playlist,
                    onPressed: () => context.read<DownloadsBloc>().add(
                      RemovePlaylistDownloadRequested(playlist.id),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: tracks.isEmpty
                ? Center(child: Text(context.l10n.noDownloadedTracksInPlaylist))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];

                      return DownloadedTrackCard(
                        key: ValueKey(track.id),
                        track: track,
                        queue: queue,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _loadTracksIfReady() {
    final downloadsBloc = context.read<DownloadsBloc>();
    final state = downloadsBloc.state;
    if (_hasRequestedTracks || !state.isReady) {
      return;
    }

    _hasRequestedTracks = true;
    _operationErrorSerialAtRequest = state.operationErrorSerial;
    if (!state.downloadedPlaylistTracks.containsKey(widget.playlistId)) {
      downloadsBloc.add(LoadDownloadedPlaylistRequested(widget.playlistId));
    }
  }
}
