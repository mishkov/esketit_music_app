import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';

class JustAudioAudioPlayer implements AudioPlayer {
  final just_audio.AudioPlayer _audioPlayer;
  final Uri? _baseUri;

  JustAudioAudioPlayer({just_audio.AudioPlayer? audioPlayer, Uri? baseUri})
    : _audioPlayer = audioPlayer ?? just_audio.AudioPlayer(),
      _baseUri = baseUri;

  @override
  Stream<bool> get isPlayingStream => _audioPlayer.playingStream;

  @override
  Future<void> beginPlaying(Track track) async {
    final path = _extractTrackPath(track);
    final uri = _resolveTrackUri(path);
    final imageUri = _extractImageUri(track);

    await _audioPlayer.setAudioSource(
      just_audio.AudioSource.uri(
        uri,
        tag: MediaItem(
          id: uri.toString(),
          album: 'Esketit Music',
          title: track.name,
          artist: track.authors.map((author) => author.currentName).join(', '),
          artUri: imageUri,
        ),
      ),
    );
    await _audioPlayer.play();
  }

  @override
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

  Uri? _extractImageUri(Track track) {
    final image = track.image;
    if (image is! HttpFile) {
      return null;
    }

    final imagePath = image.uri.toString();
    if (imagePath.isEmpty) {
      return null;
    }

    return _resolveTrackUri(imagePath);
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
