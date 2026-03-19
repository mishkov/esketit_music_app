import 'package:esketit_music_app/domain/track.dart';

abstract class AudioPlayer {
  Stream<bool> get isPlayingStream;
  Stream<Track?> get currentTrackStream;

  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  });

  Future<void> togglePlay();

  Future<void> dispose();
}
