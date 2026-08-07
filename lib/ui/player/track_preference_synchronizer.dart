import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackPreferenceSynchronizer extends StatelessWidget {
  const TrackPreferenceSynchronizer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaylistsBloc, PlaylistsState>(
      listenWhen: (previous, current) =>
          previous.persistedTrackPreferenceChange?.serial !=
          current.persistedTrackPreferenceChange?.serial,
      listener: _onPlaylistsStateChanged,
      child: child,
    );
  }

  void _onPlaylistsStateChanged(BuildContext context, PlaylistsState state) {
    final change = state.persistedTrackPreferenceChange;
    if (change == null) {
      return;
    }

    context.read<PlayerBloc>().add(
      PersistedTrackPreferenceChanged(
        trackId: change.trackId,
        isDisliked: change.isDisliked,
        collectDislikeAnalytics: change.collectDislikeAnalytics,
        sourceContext: change.sourceContext,
        sourceQueueIndex: change.sourceQueueIndex,
        sourceWasPlaying: change.sourceWasPlaying,
      ),
    );
  }
}
