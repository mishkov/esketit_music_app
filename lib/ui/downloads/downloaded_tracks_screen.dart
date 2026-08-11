import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_track_card.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedTracksScreen extends StatelessWidget {
  const DownloadedTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.downloadedTracksTitle)),
      body: BlocBuilder<DownloadsBloc, DownloadsState>(
        buildWhen: (previous, current) =>
            previous.availability != current.availability ||
            previous.library.tracks != current.library.tracks,
        builder: (context, state) {
          if (state.availability == DownloadsAvailability.starting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isSupported) {
            return Center(
              child: Text(context.l10n.downloadsUnavailableMessage),
            );
          }

          final tracks = state.library.tracks;
          if (tracks.isEmpty) {
            return Center(child: Text(context.l10n.noDownloadedTracksMessage));
          }
          final queue = downloadedPlaybackQueue(tracks);

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              selectedTrackExists ? 100 : 16,
            ),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];

              return DownloadedTrackCard(
                key: ValueKey(track.id),
                track: track,
                queue: queue,
              );
            },
          );
        },
      ),
    );
  }
}
