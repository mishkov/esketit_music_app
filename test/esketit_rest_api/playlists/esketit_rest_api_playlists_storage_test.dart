import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/playlists/esketit_rest_api_playlists_storage.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads public playlist details from anonymous public endpoints',
    () async {
      final httpClient = _FakeHttpClient(
        responses: {
          '/public/playlists/7': const HttpResponse(
            statusCode: 200,
            response: {
              'id': 7,
              'userId': 10,
              'name': 'Road',
              'description': 'Driving playlist',
              'coverImagePath': '/covers/road.jpg',
              'visibility': 'public',
              'trackCount': 1,
              'system': false,
              'isFavorites': false,
            },
          ),
          '/authors': const HttpResponse(statusCode: 200, response: []),
          '/public/playlists/7/tracks?page=1&pageSize=100': const HttpResponse(
            statusCode: 200,
            response: {
              'items': [
                {
                  'id': 123,
                  'name': 'Track name',
                  'authorIds': [],
                  'audioFilePath': '/api/songs/file.mp3',
                  'isFavorite': false,
                  'isAvailable': true,
                },
              ],
              'page': 1,
              'pageSize': 100,
              'totalItems': 1,
              'totalPages': 1,
            },
          ),
        },
      );
      final storage = EsketitRestApiPlaylistsStorage(
        httpClient: httpClient,
        baseUri: Uri.parse('http://localhost:8080/api/'),
      );

      final details = await storage.getPublicPlaylistDetails(playlistId: 7);

      expect(details.playlist.name, 'Road');
      expect(details.playlist.visibility, PlaylistVisibility.public);
      expect(details.playlist.shareToken, isNull);
      expect(
        (details.tracks.single.file as HttpFile).uri,
        Uri.parse('http://localhost:8080/api/songs/file.mp3'),
      );
      expect(httpClient.requestedPaths, [
        '/public/playlists/7',
        '/authors',
        '/public/playlists/7/tracks?page=1&pageSize=100',
      ]);
    },
  );

  test('loads shared playlist details with encoded share token', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/shared/playlists/token%20value': const HttpResponse(
          statusCode: 200,
          response: {
            'id': 8,
            'userId': 10,
            'name': 'Shared Road',
            'description': 'Driving playlist',
            'coverImagePath': '',
            'visibility': 'shared',
            'trackCount': 0,
            'system': false,
            'isFavorites': false,
          },
        ),
        '/authors': const HttpResponse(statusCode: 200, response: []),
        '/shared/playlists/token%20value/tracks?page=1&pageSize=100':
            const HttpResponse(
              statusCode: 200,
              response: {
                'items': [],
                'page': 1,
                'pageSize': 100,
                'totalItems': 0,
                'totalPages': 1,
              },
            ),
      },
    );
    final storage = EsketitRestApiPlaylistsStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final details = await storage.getSharedPlaylistDetails(
      shareToken: 'token value',
    );

    expect(details.playlist.name, 'Shared Road');
    expect(details.playlist.visibility, PlaylistVisibility.shared);
    expect(details.tracks, isEmpty);
    expect(httpClient.requestedPaths, [
      '/shared/playlists/token%20value',
      '/authors',
      '/shared/playlists/token%20value/tracks?page=1&pageSize=100',
    ]);
  });
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.responses});

  final Map<String, HttpResponse> responses;
  final List<String> requestedPaths = <String>[];

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) async {
    requestedPaths.add(path);

    return responses[path] ??
        const HttpResponse(statusCode: 404, response: 'not found');
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

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
