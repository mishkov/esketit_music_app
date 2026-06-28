import 'package:esketit_music_app/unassigned_layer/just_audio_audio_player.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';

AudioPlayer createAudioPlayer({Uri? baseUri}) {
  return JustAudioAudioPlayer(baseUri: baseUri);
}
