import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LastAddedTracksScreenContent extends StatefulWidget {
  const LastAddedTracksScreenContent({super.key});

  @override
  State<LastAddedTracksScreenContent> createState() =>
      _LastAddedTracksScreenContentState();
}

class _LastAddedTracksScreenContentState
    extends State<LastAddedTracksScreenContent> {
  static const double _lazyLoadTriggerOffset = 240;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ScreenSkeleton(
      appBar: AppBar(title: Text(l10n.lastAddedTracksTitle)),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) =>
            previous.selectedTrack != current.selectedTrack,
        builder: (context, playerState) {
          final selectedTrackExists = playerState.selectedTrack != null;

          return BlocBuilder<TracksListBloc, TracksListState>(
            builder: (context, state) {
              if (state.isLoading && state.tracks.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null && state.tracks.isEmpty) {
                return Center(child: Text(l10n.lastAddedTracksLoadFailed));
              }

              if (state.tracks.isEmpty) {
                return Center(child: Text(l10n.noTracksYet));
              }

              return ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: selectedTrackExists ? 100 : 16,
                ),
                children: [
                  ...state.tracks.map((track) {
                    return TrackListCard(
                      track: track,
                      queue: state.tracks,
                      showImage: true,
                    );
                  }),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (state.error != null && state.tracks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(l10n.lastAddedTracksLoadFailed),
                      ),
                    ),
                  if (!state.hasMoreTracks && !state.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text(l10n.endOfResults)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final state = context.read<TracksListBloc>().state;
    if (!state.hasMoreTracks || state.isLoading) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > _lazyLoadTriggerOffset) {
      return;
    }

    context.read<TracksListBloc>().add(LoadMoreTracks());
  }
}
