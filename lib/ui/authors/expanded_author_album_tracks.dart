import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class ExpandedAuthorAlbumTracks extends StatelessWidget {
  const ExpandedAuthorAlbumTracks({
    required this.album,
    required this.tracks,
    required this.isLoading,
    required this.errorMessage,
    super.key,
  });

  final Album album;
  final List<Track>? tracks;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final safeTracks = tracks;
    if (safeTracks == null) {
      if (errorMessage != null) {
        return Text(errorMessage!);
      }

      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return const SizedBox.shrink();
    }

    if (safeTracks.isEmpty) {
      return Text(context.l10n.noTracksInAlbumYet);
    }

    final tracksQueue = safeTracks
        .where((track) => track.isAvailable)
        .toList(growable: false);
    final autoplayContext = AutoplayContext(
      sourceType: AutoplaySourceType.album,
      sourceId: album.id,
    );

    return Column(
      children: safeTracks
          .map((track) {
            return TrackListCard(
              track: track,
              queue: tracksQueue,
              autoplayContext: autoplayContext,
            );
          })
          .toList(growable: false),
    );
  }
}
