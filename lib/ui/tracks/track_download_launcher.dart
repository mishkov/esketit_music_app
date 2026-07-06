import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';

import 'track_download_launcher_stub.dart'
    if (dart.library.js_interop) 'track_download_launcher_web.dart';

bool canSaveTrackToDownloads(Track track) {
  final file = track.file;

  return track.isAvailable &&
      file is HttpFile &&
      file.uri.toString().isNotEmpty;
}

Future<void> saveTrackToDownloads(Track track) async {
  final file = track.file;
  if (file is! HttpFile || file.uri.toString().isEmpty) {
    return;
  }

  await triggerTrackDownload(file.uri, _downloadFileName(track, file.uri));
}

String _downloadFileName(Track track, Uri uri) {
  final fallbackName = 'track-${track.id}';
  final sanitizedName = track.name
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), ' ');
  final name = sanitizedName.isEmpty ? fallbackName : sanitizedName;
  final extension = _extensionFromUri(uri);

  if (extension.isEmpty ||
      name.toLowerCase().endsWith(extension.toLowerCase())) {
    return name;
  }

  return '$name$extension';
}

String _extensionFromUri(Uri uri) {
  if (uri.pathSegments.isEmpty) {
    return '';
  }

  final fileNameParts = uri.pathSegments.last.split('.');
  if (fileNameParts.length < 2 ||
      fileNameParts.first.isEmpty ||
      fileNameParts.last.isEmpty) {
    return '';
  }

  final extension = '.${fileNameParts.last}';
  if (extension.length > 8 || extension.contains('/')) {
    return '';
  }

  return extension;
}
