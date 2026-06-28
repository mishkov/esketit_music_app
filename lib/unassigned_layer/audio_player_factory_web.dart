import 'package:esketit_music_app/unassigned_layer/html_audio_element_audio_player.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';

AudioPlayer createAudioPlayer({Uri? baseUri}) {
  return HtmlAudioElementAudioPlayer(baseUri: baseUri);
}
