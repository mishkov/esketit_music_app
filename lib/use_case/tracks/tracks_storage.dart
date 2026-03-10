import 'package:esketit_music_app/domain/track.dart';

abstract class TracksStorage {
  /// If [lastFetchedTrack] is null then result list will start from begin of
  /// stored tracks.
  Future<List<Track>> getTracks({
    required int tracksPerPage,
    Track? lastFetchedTrack,
  });
}
