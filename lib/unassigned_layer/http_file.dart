import 'package:esketit_music_app/domain/file/abstract_file.dart';

class HttpFile extends AbstractFile {
  final Uri uri;

  HttpFile({required this.uri});

  @override
  List<Object> get props => [uri];
}
