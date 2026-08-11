import 'package:esketit_music_app/domain/file/abstract_file.dart';

abstract interface class DownloadSourceResolver {
  Uri? resolveRemoteUri(AbstractFile file);
}
