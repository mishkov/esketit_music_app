String publicPlaylistRoutePath(int playlistId) {
  return '/playlists/$playlistId';
}

String sharedPlaylistRoutePath(String shareToken) {
  return '/playlists/shared/${Uri.encodeComponent(shareToken)}';
}

Uri shareablePlaylistUri(String routePath, {Uri? baseUri}) {
  return (baseUri ?? Uri.base).resolve(routePath);
}
