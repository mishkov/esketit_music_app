import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/playlists/playlist_header.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareablePlaylistDetailsScreen extends StatefulWidget {
  const ShareablePlaylistDetailsScreen.public({
    required int playlistId,
    super.key,
  }) : _source = _ShareablePlaylistSource.public,
       _playlistId = playlistId,
       _shareToken = null;

  const ShareablePlaylistDetailsScreen.shared({
    required String shareToken,
    super.key,
  }) : _source = _ShareablePlaylistSource.shared,
       _playlistId = null,
       _shareToken = shareToken;

  final _ShareablePlaylistSource _source;
  final int? _playlistId;
  final String? _shareToken;

  @override
  State<ShareablePlaylistDetailsScreen> createState() =>
      _ShareablePlaylistDetailsScreenState();
}

class _ShareablePlaylistDetailsScreenState
    extends State<ShareablePlaylistDetailsScreen> {
  late Future<PlaylistDetailsSnapshot> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  @override
  void didUpdateWidget(ShareablePlaylistDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._source != widget._source ||
        oldWidget._playlistId != widget._playlistId ||
        oldWidget._shareToken != widget._shareToken) {
      _detailsFuture = _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<PlaylistDetailsSnapshot>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final details = snapshot.data;
        final playlist = details?.playlist;
        final selectedTrackExists = context.select<PlayerBloc, bool>(
          (bloc) => bloc.state.selectedTrack != null,
        );

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(playlist?.name ?? l10n.playlistFallbackTitle),
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.none || ConnectionState.waiting => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when snapshot.hasError => Center(
              child: Text(l10n.playlistNotFound),
            ),
            _ when details == null => Center(
              child: Text(l10n.playlistNotFound),
            ),
            _ => _PlaylistDetailsBody(
              details: details,
              selectedTrackExists: selectedTrackExists,
            ),
          },
        );
      },
    );
  }

  Future<PlaylistDetailsSnapshot> _loadDetails() {
    final storage = context.read<ShareablePlaylistsStorage>();

    return switch (widget._source) {
      _ShareablePlaylistSource.public => storage.getPublicPlaylistDetails(
        playlistId: widget._playlistId!,
      ),
      _ShareablePlaylistSource.shared => storage.getSharedPlaylistDetails(
        shareToken: widget._shareToken!,
      ),
    };
  }
}

class _PlaylistDetailsBody extends StatelessWidget {
  const _PlaylistDetailsBody({
    required this.details,
    required this.selectedTrackExists,
  });

  final PlaylistDetailsSnapshot details;
  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playlist = details.playlist;
    final tracks = details.tracks;

    return Padding(
      padding: EdgeInsets.only(bottom: selectedTrackExists ? 100 : 0),
      child: Column(
        children: [
          PlaylistHeader(playlist: playlist),
          Expanded(
            child: tracks.isEmpty
                ? Center(child: Text(l10n.playlistHasNoTracksYet))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];

                      return TrackListCard(
                        key: ValueKey(
                          'shareable-playlist-${playlist.id}-track-${track.id}',
                        ),
                        track: track,
                        queue: _availableTracks(tracks),
                        showAddToPlaylistsAction: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Track> _availableTracks(List<Track> tracks) {
    return tracks.where((track) => track.isAvailable).toList(growable: false);
  }
}

enum _ShareablePlaylistSource { public, shared }
