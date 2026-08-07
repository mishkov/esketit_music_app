import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/playlists/playlist_track_card.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class PlaylistTracksList extends StatelessWidget {
  const PlaylistTracksList({
    required this.playlist,
    required this.tracks,
    required this.isReordering,
    required this.onReorder,
    super.key,
  });

  final Playlist playlist;
  final List<Track> tracks;
  final bool isReordering;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.fromLTRB(16, 0, 16, 16);
    final queue = tracks
        .where((track) => track.isAvailable)
        .toList(growable: false);
    final isEditable = !playlist.system && playlist.kind == PlaylistKind.custom;
    final autoplayContext = AutoplayContext(
      sourceType: AutoplaySourceType.playlist,
      sourceId: playlist.id,
    );

    if (!isEditable) {
      return ListView.builder(
        padding: padding,
        itemCount: tracks.length,
        itemBuilder: (context, index) => PlaylistTrackCard(
          key: _trackKey(playlist, tracks[index]),
          playlist: playlist,
          track: tracks[index],
          queue: queue,
          autoplayContext: autoplayContext,
          isEditable: false,
        ),
      );
    }

    return ReorderableListView.builder(
      padding: padding,
      onReorder: isReordering ? (_, _) {} : onReorder,
      itemCount: tracks.length,
      itemBuilder: (context, index) => PlaylistTrackCard(
        key: _trackKey(playlist, tracks[index]),
        playlist: playlist,
        track: tracks[index],
        queue: queue,
        autoplayContext: autoplayContext,
        isEditable: true,
      ),
    );
  }

  ValueKey<String> _trackKey(Playlist playlist, Track track) {
    return ValueKey('playlist-${playlist.id}-track-${track.id}');
  }
}
