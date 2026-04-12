import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_screen_body.dart';
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

        return ScreenSkeleton(
          enableBottomPlayer: false,
          appBar: AppBar(
            title: Text(context.l10n.trackScreenNowPlayingLabel),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
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
}
