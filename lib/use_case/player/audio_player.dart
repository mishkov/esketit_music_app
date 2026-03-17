import 'package:esketit_music_app/domain/track.dart';

abstract class AudioPlayer {
  Future<void> beginPlaying(Track track);

  Future<void> togglePlay();
}
