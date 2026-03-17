import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

class JustAudioAudioPlayer implements AudioPlayer {
  final just_audio.AudioPlayer _audioPlayer;
  final Uri? _baseUri;

  JustAudioAudioPlayer({just_audio.AudioPlayer? audioPlayer, Uri? baseUri})
    : _audioPlayer = audioPlayer ?? just_audio.AudioPlayer(),
      _baseUri = baseUri;

  @override
  Future<void> beginPlaying(Track track) async {
    final path = _extractTrackPath(track);
    final uri = _resolveTrackUri(path);

    await _audioPlayer.setUrl(uri.toString());
    await _audioPlayer.play();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  String _extractTrackPath(Track track) {
    final file = track.file;
    if (file is! HttpFile) {
      throw StateError('Track file must be HttpFile');
    }

    final path = file.uri.toString();
    if (path.isEmpty) {
      throw StateError('Track file path is empty');
    }
    return path;
  }

  Uri _resolveTrackUri(String path) {
    final candidate = Uri.tryParse(path);
    if (candidate != null && candidate.hasScheme) {
      return candidate;
    }

    if (_baseUri == null) {
      throw StateError('Relative track path requires baseUri: $path');
    }

    return _baseUri.resolve(path);
  }
  
  @override
  Future<void> togglePlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }
    await _audioPlayer.play();
  }
}
