import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/tracks/esketit_rest_api_tracks_storage.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads one track by ID for direct navigation', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/authors': const HttpResponse(
          statusCode: 200,
          response: [
            {'id': 7, 'currentName': 'Artist Name', 'photos': []},
          ],
        ),
        '/tracks/123': const HttpResponse(
          statusCode: 200,
          response: {
            'id': 123,
            'name': 'Shared track',
            'audioFilePath': 'track.mp3',
            'coverImagePath': 'cover.jpg',
            'authorIds': [7],
            'isFavorite': false,
            'isAvailable': true,
          },
        ),
      },
    );
    final storage = EsketitRestApiTracksStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final track = await storage.getTrack(trackId: 123);

    expect(httpClient.requestedPaths, ['/tracks/123', '/authors']);
    expect(track?.id, 123);
    expect(track?.name, 'Shared track');
    expect(track?.authors.single.currentName, 'Artist Name');
  });

  test('returns null when a directly requested track does not exist', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/tracks/404': const HttpResponse(
          statusCode: 404,
          response: 'not found',
        ),
      },
    );
    final storage = EsketitRestApiTracksStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    expect(await storage.getTrack(trackId: 404), isNull);
    expect(httpClient.requestedPaths, ['/tracks/404']);
  });

  test(
    'loads the album cover when a direct track has only an album ID',
    () async {
      final httpClient = _FakeHttpClient(
        responses: {
          '/tracks/123': const HttpResponse(
            statusCode: 200,
            response: {
              'id': 123,
              'name': 'Shared track',
              'audioFilePath': 'track.mp3',
              'albumId': 9,
              'authorIds': [],
              'isFavorite': false,
              'isAvailable': true,
            },
          ),
          '/authors': const HttpResponse(statusCode: 200, response: []),
          '/albums/9': const HttpResponse(
            statusCode: 200,
            response: {'id': 9, 'imagePath': '', 'coverImagePath': 'album.jpg'},
          ),
        },
      );
      final storage = EsketitRestApiTracksStorage(
        httpClient: httpClient,
        baseUri: Uri.parse('http://localhost:8080/api/'),
      );

      final track = await storage.getTrack(trackId: 123);

      expect(httpClient.requestedPaths, [
        '/tracks/123',
        '/authors',
        '/albums/9',
      ]);
      expect(
        (track?.image as HttpFile).uri,
        Uri.parse('http://localhost:8080/api/album-covers/album.jpg'),
      );
    },
  );

  test('loads tracks with added date descending sorting params', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/authors': const HttpResponse(statusCode: 200, response: []),
        '/tracks?page=2&pageSize=20&sort=createdAt&order=desc':
            const HttpResponse(
              statusCode: 200,
              response: {
                'items': [],
                'page': 2,
                'pageSize': 20,
                'totalItems': 40,
                'totalPages': 2,
              },
            ),
      },
    );
    final storage = EsketitRestApiTracksStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    await storage.getTracks(
      page: 2,
      pageSize: 20,
      sort: TracksSort.addedAt,
      order: TracksSortOrder.descending,
    );

    expect(httpClient.requestedPaths, [
      '/authors',
      '/tracks?page=2&pageSize=20&sort=createdAt&order=desc',
    ]);
  });

  test('parses authors and cover image for tracks page', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/authors': const HttpResponse(
          statusCode: 200,
          response: [
            {
              'id': 7,
              'currentName': 'Artist Name',
              'photos': ['artist.jpg'],
            },
          ],
        ),
        '/tracks?page=1&pageSize=6&sort=createdAt&order=desc':
            const HttpResponse(
              statusCode: 200,
              response: {
                'items': [
                  {
                    'id': 123,
                    'name': 'Track name',
                    'audioFilePath': 'track.mp3',
                    'coverImagePath': '/api/album-covers/album.jpg',
                    'authorIds': [7],
                    'isFavorite': false,
                    'isAvailable': true,
                  },
                ],
                'page': 1,
                'pageSize': 6,
                'totalItems': 1,
                'totalPages': 1,
              },
            ),
      },
    );
    final storage = EsketitRestApiTracksStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final page = await storage.getTracks(
      page: 1,
      pageSize: 6,
      sort: TracksSort.addedAt,
      order: TracksSortOrder.descending,
    );
    final track = page.items.single;

    expect(track.name, 'Track name');
    expect(track.authors.single.currentName, 'Artist Name');
    expect(
      track.authors.single.primaryPhotoUrl,
      'http://localhost:8080/api/author-photos/artist.jpg',
    );
    expect(
      (track.image as HttpFile).uri,
      Uri.parse('http://localhost:8080/api/album-covers/album.jpg'),
    );
    expect(
      (track.file as HttpFile).uri,
      Uri.parse('http://localhost:8080/api/songs/track.mp3'),
    );
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
