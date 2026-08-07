import 'package:esketit_music_app/ui/tracks/track_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a track route path from a track ID', () {
    expect(trackRoutePath(42), '/tracks/42');
  });

  group('trackIdFromRouteName', () {
    test('parses a track ID from a valid route', () {
      expect(trackIdFromRouteName('/tracks/42'), 42);
    });

    test('parses a route with query parameters and a fragment', () {
      expect(trackIdFromRouteName('/tracks/42?source=share#lyrics'), 42);
    });

    test('rejects malformed track routes', () {
      expect(trackIdFromRouteName('/tracks'), isNull);
      expect(trackIdFromRouteName('/tracks/not-a-number'), isNull);
      expect(trackIdFromRouteName('/tracks/0'), isNull);
      expect(trackIdFromRouteName('/tracks/42/lyrics'), isNull);
      expect(trackIdFromRouteName('/authors/42'), isNull);
    });
  });

  test('shareable track URI does not keep query or fragment', () {
    final uri = shareableTrackUri(
      42,
      baseUri: Uri.parse('http://localhost:8081/current?old=value#section'),
    );

    expect(uri.toString(), 'http://localhost:8081/tracks/42');
  });
}
