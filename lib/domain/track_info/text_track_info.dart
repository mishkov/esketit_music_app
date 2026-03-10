import 'package:esketit_music_app/domain/track_info/track_info.dart';

class TextTrackInfo extends TrackInfo {
  final String title;
  final String text;

  TextTrackInfo({required this.title, required this.text});

  @override
  List<Object?> get props => [title, text];
}
