import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/download_source_resolver.dart';

class HttpDownloadSourceResolver implements DownloadSourceResolver {
  const HttpDownloadSourceResolver();

  @override
  Uri? resolveRemoteUri(AbstractFile file) {
    if (file is! HttpFile || file.uri.toString().isEmpty) {
      return null;
    }

    return file.uri;
  }
}
