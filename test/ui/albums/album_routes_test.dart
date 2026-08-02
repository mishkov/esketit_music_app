import 'package:esketit_music_app/ui/albums/album_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an album route path from an album ID', () {
    expect(albumRoutePath(42), '/albums/42');
  });

  group('albumIdFromRouteName', () {
    test('parses an album ID from a valid route', () {
      expect(albumIdFromRouteName('/albums/42'), 42);
    });

    test('parses a route with query parameters and a fragment', () {
      expect(albumIdFromRouteName('/albums/42?source=share#tracks'), 42);
    });

    test('rejects malformed album routes', () {
      expect(albumIdFromRouteName('/albums'), isNull);
      expect(albumIdFromRouteName('/albums/not-a-number'), isNull);
      expect(albumIdFromRouteName('/albums/0'), isNull);
      expect(albumIdFromRouteName('/albums/42/tracks'), isNull);
      expect(albumIdFromRouteName('/authors/42'), isNull);
    });
  });

  test('shareable album URI does not keep query or fragment', () {
    final uri = shareableAlbumUri(
      42,
      baseUri: Uri.parse('http://localhost:8081/current?old=value#section'),
    );

    expect(uri.toString(), 'http://localhost:8081/albums/42');
  });
}
