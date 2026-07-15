import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/last_added_tracks_screen.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LastAddedTracksSectionContent extends StatelessWidget {
  const LastAddedTracksSectionContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TracksListBloc, TracksListState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.lastAddedTracksTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openLastAddedTracksScreen(context),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.viewMoreButton),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.tracks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.error != null && state.tracks.isEmpty)
              Text(l10n.lastAddedTracksLoadFailed)
            else if (state.tracks.isEmpty)
              Text(l10n.noTracksYet)
            else
              ...state.tracks.map((track) {
                return TrackListCard(
                  track: track,
                  queue: state.tracks,
                  showImage: true,
                );
              }),
          ],
        );
      },
    );
  }

  void _openLastAddedTracksScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LastAddedTracksScreen(),
      ),
    );
  }
}
