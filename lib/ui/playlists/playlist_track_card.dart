import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class PlaylistTrackCard extends StatelessWidget {
  const PlaylistTrackCard({
    required this.playlist,
    required this.track,
    required this.queue,
    required this.autoplayContext,
    required this.isEditable,
    super.key,
  });

  final Playlist playlist;
  final Track track;
  final List<Track> queue;
  final AutoplayContext autoplayContext;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return TrackListCard(
      track: track,
      queue: queue,
      autoplayContext: autoplayContext,
      playlistIdForRemoval: isEditable ? playlist.id : null,
      showAddToPlaylistsAction: isEditable,
      showImage: true,
    );
  }
}
