import 'dart:async';

import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_screen.dart';
import 'package:esketit_music_app/ui/tracks/track_routes.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/track_details/bloc/track_details_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrackRouteScreen extends StatefulWidget {
  const TrackRouteScreen({required this.trackId, this.initialTrack, super.key});

  final int trackId;
  final Track? initialTrack;

  @override
  State<TrackRouteScreen> createState() => _TrackRouteScreenState();
}

class _TrackRouteScreenState extends State<TrackRouteScreen> {
  bool _followsPlayback = false;
  int? _currentRouteTrackId;

  @override
  void initState() {
    super.initState();
    _followsPlayback = _hasMatchingInitialTrack;
    _currentRouteTrackId = widget.trackId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.read<PlayerBloc>().state.selectedTrack?.id == widget.trackId) {
      _followsPlayback = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: _createTrackDetailsBloc,
      child: BlocConsumer<PlayerBloc, PlayerState>(
        listenWhen: _selectedTrackChanged,
        listener: _onPlayerStateChanged,
        buildWhen: _selectedTrackChanged,
        builder: (context, playerState) {
          return BlocBuilder<TrackDetailsBloc, TrackDetailsState>(
            builder: (context, trackDetailsState) =>
                _buildContent(context, trackDetailsState, playerState),
          );
        },
      ),
    );
  }

  TrackDetailsBloc _createTrackDetailsBloc(BuildContext context) {
    final effectiveInitialTrack = _hasMatchingInitialTrack
        ? widget.initialTrack
        : null;
    final bloc = TrackDetailsBloc(
      initialState: TrackDetailsState(
        trackId: widget.trackId,
        track: effectiveInitialTrack,
        isLoading: effectiveInitialTrack == null,
        error: null,
      ),
      tracksStorage: context.read<TracksStorage>(),
      errorReporter: context.read<ErrorReporter>(),
    );
    if (effectiveInitialTrack == null) {
      bloc.add(LoadTrackDetails(widget.trackId));
    }

    return bloc;
  }

  bool _selectedTrackChanged(PlayerState previous, PlayerState current) {
    return previous.selectedTrack?.id != current.selectedTrack?.id;
  }

  void _onPlayerStateChanged(BuildContext context, PlayerState state) {
    final selectedTrack = state.selectedTrack;
    if (selectedTrack == null) {
      return;
    }

    if (!_followsPlayback) {
      if (selectedTrack.id == widget.trackId) {
        _followsPlayback = true;
      }

      return;
    }

    if (selectedTrack.id == _currentRouteTrackId) {
      return;
    }

    _currentRouteTrackId = selectedTrack.id;
    unawaited(
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(trackRoutePath(selectedTrack.id)),
        replace: true,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TrackDetailsState trackDetailsState,
    PlayerState playerState,
  ) {
    final track = _followsPlayback
        ? playerState.selectedTrack ?? trackDetailsState.track
        : trackDetailsState.track;
    if (track != null) {
      return TrackScreen(track: track);
    }

    return ScreenSkeleton(
      enableBottomPlayer: false,
      appBar: AppBar(title: Text(context.l10n.trackScreenTitle)),
      body: trackDetailsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Text(
                trackDetailsState.error == null
                    ? context.l10n.trackNotFound
                    : context.l10n.trackLoadFailed,
              ),
            ),
    );
  }

  bool get _hasMatchingInitialTrack =>
      widget.initialTrack?.id == widget.trackId;
}
