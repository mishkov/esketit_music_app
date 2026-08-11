import 'package:esketit_music_app/unassigned_layer/download_aware_audio_player.dart';
import 'package:esketit_music_app/unassigned_layer/just_audio_audio_player.dart';
import 'package:esketit_music_app/use_case/downloads/downloaded_library_storage.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';

AudioPlayer createAudioPlayer({
  Uri? baseUri,
  DownloadedLibraryStorage? downloadedLibraryStorage,
}) {
  final player = JustAudioAudioPlayer(baseUri: baseUri);
  if (downloadedLibraryStorage == null) {
    return player;
  }

  return DownloadAwareAudioPlayer(
    delegate: player,
    downloadedLibraryStorage: downloadedLibraryStorage,
  );
}
