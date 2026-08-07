String albumRoutePath(int albumId) {
  return '/albums/$albumId';
}

int? albumIdFromRouteName(String routeName) {
  final uri = Uri.tryParse(routeName);
  final segments = uri?.pathSegments ?? const <String>[];

  if (segments.length != 2 || segments.first != 'albums') {
    return null;
  }

  final albumId = int.tryParse(segments[1]);

  return albumId != null && albumId > 0 ? albumId : null;
}

Uri shareableAlbumUri(int albumId, {Uri? baseUri}) {
  return (baseUri ?? Uri.base).resolve(albumRoutePath(albumId));
}
