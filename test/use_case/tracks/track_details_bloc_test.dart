import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/tracks/track_details/bloc/track_details_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final track = _track(42);

  blocTest<TrackDetailsBloc, TrackDetailsState>(
    'loads a directly addressed track without interacting with playback',
    build: () => TrackDetailsBloc(
      initialState: _initialState(),
      tracksStorage: _FakeTracksStorage(track: track),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(const LoadTrackDetails(42)),
    expect: () => [
      const TrackDetailsState(
        trackId: 42,
        track: null,
        isLoading: true,
        error: null,
      ),
      TrackDetailsState(
        trackId: 42,
        track: track,
        isLoading: false,
        error: null,
      ),
    ],
  );

  blocTest<TrackDetailsBloc, TrackDetailsState>(
    'keeps a missing directly addressed track distinct from a load error',
    build: () => TrackDetailsBloc(
      initialState: _initialState(),
      tracksStorage: _FakeTracksStorage(track: null),
      errorReporter: _FakeErrorReporter(),
    ),
    act: (bloc) => bloc.add(const LoadTrackDetails(42)),
    expect: () => const [
      TrackDetailsState(trackId: 42, track: null, isLoading: true, error: null),
      TrackDetailsState(
        trackId: 42,
        track: null,
        isLoading: false,
        error: null,
      ),
    ],
  );
}

TrackDetailsState _initialState() {
  return const TrackDetailsState(
    trackId: 42,
    track: null,
    isLoading: false,
    error: null,
  );
}

class _FakeTracksStorage implements TracksStorage {
  const _FakeTracksStorage({required this.track});

  final Track? track;

  @override
  Future<Track?> getTrack({required int trackId}) async => track;

  @override
  Future<PaginatedTracks> getTracks({
    required int page,
    required int pageSize,
    TracksSort sort = TracksSort.id,
    TracksSortOrder order = TracksSortOrder.ascending,
  }) {
    throw UnimplementedError();
  }
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Artist', photos: [])],
    addionalInfo: const [],
    file: _FakeFile(),
    image: _FakeFile(),
    isFavorite: false,
    isAvailable: true,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
