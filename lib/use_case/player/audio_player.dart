import 'package:esketit_music_app/domain/track.dart';

abstract class AudioPlayer {
  Duration get currentPosition;
  int? get currentIndex;
  Stream<bool> get isPlayingStream;
  Stream<Track?> get currentTrackStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get hasPreviousTrackStream;
  Stream<bool> get hasNextTrackStream;

  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  });
  Future<void> appendToQueue(List<Track> tracks);
  Future<void> removeUpcomingTracks(Set<int> trackIds);

  Future<void> togglePlay();
  Future<void> skipToPreviousTrack();
  Future<void> skipToNextTrack();
  Future<void> seekTo(Duration position);
  Future<void> stop();

  Future<void> dispose();
}
