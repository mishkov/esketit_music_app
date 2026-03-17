import 'package:esketit_music_app/domain/track.dart';

abstract class AudioPlayer {
  Stream<bool> get isPlayingStream;

  Future<void> beginPlaying(Track track);

  Future<void> togglePlay();

  Future<void> dispose();
}
