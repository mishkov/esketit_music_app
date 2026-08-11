const downloadManagerRoutePath = '/downloads/manage';
const downloadedTracksRoutePath = '/downloads/tracks';
const downloadedAuthorsRoutePath = '/downloads/authors';
const downloadedAlbumsRoutePath = '/downloads/albums';
const downloadedPlaylistsRoutePath = '/downloads/playlists';

String downloadedAuthorDetailsRoutePath(int authorId) {
  return '$downloadedAuthorsRoutePath/$authorId';
}

String downloadedAlbumDetailsRoutePath(int albumId) {
  return '$downloadedAlbumsRoutePath/$albumId';
}

String downloadedPlaylistDetailsRoutePath(int playlistId) {
  return '$downloadedPlaylistsRoutePath/$playlistId';
}

int? downloadedAuthorIdFromRouteName(String routeName) {
  return _downloadedEntityIdFromRouteName(
    routeName,
    collectionSegment: 'authors',
  );
}

int? downloadedAlbumIdFromRouteName(String routeName) {
  return _downloadedEntityIdFromRouteName(
    routeName,
    collectionSegment: 'albums',
  );
}

int? downloadedPlaylistIdFromRouteName(String routeName) {
  return _downloadedEntityIdFromRouteName(
    routeName,
    collectionSegment: 'playlists',
  );
}

int? _downloadedEntityIdFromRouteName(
  String routeName, {
  required String collectionSegment,
}) {
  final uri = Uri.tryParse(routeName);
  final segments = uri?.pathSegments ?? const <String>[];
  if (segments.length != 3 ||
      segments.first != 'downloads' ||
      segments[1] != collectionSegment) {
    return null;
  }

  final entityId = int.tryParse(segments[2]);

  return entityId != null && entityId > 0 ? entityId : null;
}
