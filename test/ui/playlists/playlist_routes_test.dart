import 'package:esketit_music_app/ui/playlists/playlist_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shareable playlist URI does not keep query or fragment', () {
    final uri = shareablePlaylistUri(
      '/playlists/2',
      baseUri: Uri.parse('http://localhost:8081/current?old=value#section'),
    );

    expect(uri.toString(), 'http://localhost:8081/playlists/2');
  });
}
