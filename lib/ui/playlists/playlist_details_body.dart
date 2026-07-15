import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/playlists/playlist_header.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';

class PlaylistDetailsBody extends StatelessWidget {
  const PlaylistDetailsBody({
    required this.details,
    required this.selectedTrackExists,
    super.key,
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
                        showImage: true,
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
