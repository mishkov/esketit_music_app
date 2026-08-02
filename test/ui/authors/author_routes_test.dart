import 'package:esketit_music_app/ui/authors/author_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an author route path from an author ID', () {
    expect(authorRoutePath(42), '/authors/42');
  });

  group('authorIdFromRouteName', () {
    test('parses an author ID from a valid route', () {
      expect(authorIdFromRouteName('/authors/42'), 42);
    });

    test('parses a route with query parameters and a fragment', () {
      expect(authorIdFromRouteName('/authors/42?source=share#albums'), 42);
    });

    test('rejects malformed author routes', () {
      expect(authorIdFromRouteName('/authors'), isNull);
      expect(authorIdFromRouteName('/authors/not-a-number'), isNull);
      expect(authorIdFromRouteName('/authors/0'), isNull);
      expect(authorIdFromRouteName('/authors/42/albums'), isNull);
      expect(authorIdFromRouteName('/playlists/42'), isNull);
    });
  });
}
