import 'package:esketit_music_app/esketit_rest_api/catalog/esketit_rest_api_catalog_storage.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search sends query, page, and pageSize params', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/search?query=Synth&page=2&pageSize=25': const HttpResponse(
          statusCode: 200,
          response: {
            'items': [],
            'page': 2,
            'pageSize': 25,
            'totalItems': 0,
            'totalPages': 0,
          },
        ),
      },
    );
    final storage = EsketitRestApiCatalogStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080'),
    );

    await storage.search(query: 'Synth', page: 2, pageSize: 25);

    expect(httpClient.requestedPaths, [
      '/search?query=Synth&page=2&pageSize=25',
    ]);
  });

  test(
    'search parses track authors and cover image path from response',
    () async {
      final httpClient = _FakeHttpClient(
        responses: {
          '/search?query=Track&page=1&pageSize=20': const HttpResponse(
            statusCode: 200,
            response: {
              'items': [
                {
                  'type': 'track',
                  'track': {
                    'id': 123,
                    'name': 'Track name',
                    'audioFilePath': 'track.mp3',
                    'authorIds': [1],
                    'authors': [
                      {
                        'id': 1,
                        'currentName': 'Artist Name',
                        'photos': ['/api/author-photos/artist.jpg'],
                      },
                    ],
                    'coverImagePath': 'album-cover.jpg',
                    'isFavorite': false,
                    'isAvailable': true,
                  },
                },
              ],
              'page': 1,
              'pageSize': 20,
              'totalItems': 1,
              'totalPages': 1,
            },
          ),
        },
      );
      final storage = EsketitRestApiCatalogStorage(
        httpClient: httpClient,
        baseUri: Uri.parse('http://localhost:8080'),
      );

      final results = await storage.search(
        query: 'Track',
        page: 1,
        pageSize: 20,
      );
      final track = results.items.single.track!;

      expect(track.authors.single.currentName, 'Artist Name');
      expect(
        track.authors.single.primaryPhotoUrl,
        'http://localhost:8080/api/author-photos/artist.jpg',
      );
      expect(
        (track.image as HttpFile).uri,
        Uri.parse('http://localhost:8080/album-covers/album-cover.jpg'),
      );
    },
  );

  test('search parses playlist results from response', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/search?query=Road&page=1&pageSize=20': const HttpResponse(
          statusCode: 200,
          response: {
            'items': [
              {
                'type': 'playlist',
                'playlist': {
                  'id': 7,
                  'userId': 10,
                  'name': 'Road',
                  'description': 'Driving playlist',
                  'coverImagePath': '/covers/road.jpg',
                  'visibility': 'public',
                  'trackCount': 12,
                  'system': false,
                  'isFavorites': false,
                },
              },
            ],
            'page': 1,
            'pageSize': 20,
            'totalItems': 1,
            'totalPages': 1,
          },
        ),
      },
    );
    final storage = EsketitRestApiCatalogStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final results = await storage.search(query: 'Road', page: 1, pageSize: 20);
    final playlist = results.items.single.playlist!;

    expect(playlist.name, 'Road');
    expect(playlist.visibility, PlaylistVisibility.public);
    expect(playlist.coverImagePath, 'http://localhost:8080/covers/road.jpg');
  });

  test(
    'resolves legacy bare author photo file names under author photos',
    () async {
      final httpClient = _FakeHttpClient(
        responses: {
          '/search?query=Artist&page=1&pageSize=20': const HttpResponse(
            statusCode: 200,
            response: {
              'items': [
                {
                  'type': 'author',
                  'author': {
                    'id': 1,
                    'currentName': 'Artist Name',
                    'photos': ['artist.jpg'],
                  },
                },
              ],
              'page': 1,
              'pageSize': 20,
              'totalItems': 1,
              'totalPages': 1,
            },
          ),
        },
      );
      final storage = EsketitRestApiCatalogStorage(
        httpClient: httpClient,
        baseUri: Uri.parse('http://localhost:8080/api/'),
      );

      final results = await storage.search(
        query: 'Artist',
        page: 1,
        pageSize: 20,
      );

      expect(
        results.items.single.author!.primaryPhotoUrl,
        'http://localhost:8080/api/author-photos/artist.jpg',
      );
    },
  );
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
