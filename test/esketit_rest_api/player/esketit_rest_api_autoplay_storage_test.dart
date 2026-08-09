import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/player/esketit_rest_api_autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes dislike state from defensive autoplay results', () async {
    final httpClient = _FakeHttpClient();
    final storage = EsketitRestApiAutoplayStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );
    const context = AutoplayContext(
      sourceType: AutoplaySourceType.playlist,
      sourceId: 7,
    );

    final batch = await storage.getNextTracks(
      context: context,
      count: 10,
      recentTrackIds: const [1],
      excludedTrackIds: const [2],
    );

    expect(batch.context, context);
    expect(batch.strategy, 'playlist');
    expect(batch.tracks.single.isDisliked, isTrue);
    expect(httpClient.postedBody, {
      'sourceType': 'playlist',
      'sourceId': 7,
      'profile': 'default',
      'count': 10,
      'recentTrackIds': [1],
      'excludedTrackIds': [2],
    });
  });

  test('serializes author autoplay context', () async {
    final httpClient = _FakeHttpClient();
    final storage = EsketitRestApiAutoplayStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    await storage.getNextTracks(
      context: const AutoplayContext(
        sourceType: AutoplaySourceType.author,
        sourceId: 42,
      ),
      count: 10,
      recentTrackIds: const [],
      excludedTrackIds: const [],
    );

    expect(httpClient.postedBody, {
      'sourceType': 'author',
      'sourceId': 42,
      'profile': 'default',
      'count': 10,
      'recentTrackIds': <int>[],
      'excludedTrackIds': <int>[],
    });
  });
}

class _FakeHttpClient implements HttpClient {
  Object? postedBody;

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    if (path == '/authors') {
      return const HttpResponse(statusCode: 200, response: []);
    }

    return const HttpResponse(statusCode: 404, response: 'not found');
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    postedBody = body;

    return const HttpResponse(
      statusCode: 200,
      response: {
        'strategy': 'playlist',
        'tracks': [
          {
            'id': 3,
            'name': 'Defensive result',
            'authorIds': [],
            'audioFilePath': '/api/songs/track.mp3',
            'coverImagePath': '/api/album-covers/cover.jpg',
            'isFavorite': false,
            'isDisliked': true,
            'isAvailable': true,
          },
        ],
      },
    );
  }

  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
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

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
