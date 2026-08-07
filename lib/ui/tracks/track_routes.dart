String trackRoutePath(int trackId) {
  return '/tracks/$trackId';
}

int? trackIdFromRouteName(String routeName) {
  final uri = Uri.tryParse(routeName);
  final segments = uri?.pathSegments ?? const <String>[];

  if (segments.length != 2 || segments.first != 'tracks') {
    return null;
  }

  final trackId = int.tryParse(segments[1]);

  return trackId != null && trackId > 0 ? trackId : null;
}

Uri shareableTrackUri(int trackId, {Uri? baseUri}) {
  return (baseUri ?? Uri.base).resolve(trackRoutePath(trackId));
}
