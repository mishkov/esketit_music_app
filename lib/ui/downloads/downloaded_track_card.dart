import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:flutter/material.dart';

class DownloadedTrackCard extends StatelessWidget {
  const DownloadedTrackCard({
    required this.track,
    required this.queue,
    this.showImage = true,
    super.key,
  });

  final Track track;
  final List<Track> queue;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return TrackListCard(
      track: track,
      queue: queue,
      showAddToPlaylistsAction: false,
      showImage: showImage,
    );
  }
}

List<Track> downloadedPlaybackQueue(Iterable<Track> tracks) {
  return tracks
      .where((track) => track.file is LocalFile && track.isAvailable)
      .toList(growable: false);
}
