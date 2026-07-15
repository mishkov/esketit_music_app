import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/ui/tracks/last_added_tracks_section_content.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LastAddedTracksSection extends StatelessWidget {
  const LastAddedTracksSection({super.key});

  static const int _tracksLimit = 6;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TracksListBloc(
        initialState: const TracksListState(
          tracks: [],
          page: 0,
          pageSize: _tracksLimit,
          totalItems: 0,
          totalPages: 1,
          isLoading: false,
          error: null,
        ),
        tracksStorage: context.read<TracksStorage>(),
        errorReporter: context.read<ErrorReporter>(),
        sort: TracksSort.addedAt,
        order: TracksSortOrder.descending,
      )..add(LoadMoreTracks()),
      child: const LastAddedTracksSectionContent(),
    );
  }
}
