import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/tracks/esketit_rest_api_lyrics_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns plain lyrics from dedicated lyrics endpoint', () async {
    final storage = EsketitRestApiLyricsStorage(
      httpClient: _FakeHttpClient(
        response: const HttpResponse(
          statusCode: 200,
          response: {
            'trackId': 42,
            'type': 'plain',
            'languageCode': 'en',
            'isVerified': true,
            'source': 'artist',
            'plainText': 'Full lyrics here',
            'lines': [],
          },
        ),
      ),
    );

    final lyrics = await storage.getTrackLyrics(trackId: 42);

    expect(
      lyrics,
      const TrackLyrics(
        trackId: 42,
        type: TrackLyricsType.plain,
        languageCode: 'en',
        isVerified: true,
        source: 'artist',
        plainText: 'Full lyrics here',
        lines: [],
      ),
    );
  });

  test('returns null when lyrics are missing', () async {
    final storage = EsketitRestApiLyricsStorage(
      httpClient: _FakeHttpClient(
        response: const HttpResponse(statusCode: 404, response: null),
      ),
    );

    final lyrics = await storage.getTrackLyrics(trackId: 42);

    expect(lyrics, isNull);
  });
}

class _FakeHttpClient implements HttpClient {
  const _FakeHttpClient({required this.response});

  final HttpResponse response;

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    return response;
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }
}
