import 'package:esketit_music_app/domain/track_lyrics.dart';

abstract class LyricsStorage {
  Future<TrackLyrics?> getTrackLyrics({required int trackId});
}
