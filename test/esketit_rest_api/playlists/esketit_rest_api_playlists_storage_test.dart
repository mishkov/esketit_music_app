import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/esketit_rest_api/playlists/esketit_rest_api_playlists_storage.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('omits empty playlist description when creating playlist', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/playlists': const HttpResponse(
          statusCode: 200,
          response: {
            'id': 7,
            'userId': 10,
            'name': 'Road',
            'description': '',
            'coverImagePath': '',
            'visibility': 'private',
            'trackCount': 0,
            'system': false,
            'isFavorites': false,
          },
        ),
      },
    );
    final storage = EsketitRestApiPlaylistsStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final playlist = await storage.createPlaylist(
      const PlaylistUpsertInput(
        name: 'Road',
        coverImagePath: '',
        visibility: PlaylistVisibility.private,
      ),
    );

    expect(playlist.description, '');
    expect(httpClient.requestedPaths, ['/playlists']);
    expect(httpClient.bodies.single, {
      'name': 'Road',
      'coverImagePath': '',
      'visibility': 'private',
    });
  });

  test('sends provided playlist description when creating playlist', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/playlists': const HttpResponse(
          statusCode: 200,
          response: {
            'id': 7,
            'userId': 10,
            'name': 'Road',
            'description': 'Driving playlist',
            'coverImagePath': '',
            'visibility': 'private',
            'trackCount': 0,
            'system': false,
            'isFavorites': false,
          },
        ),
      },
    );
    final storage = EsketitRestApiPlaylistsStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final playlist = await storage.createPlaylist(
      const PlaylistUpsertInput(
        name: 'Road',
        description: 'Driving playlist',
        coverImagePath: '',
        visibility: PlaylistVisibility.private,
      ),
    );

    expect(playlist.description, 'Driving playlist');
    expect(httpClient.requestedPaths, ['/playlists']);
    expect(httpClient.bodies.single, {
      'name': 'Road',
      'description': 'Driving playlist',
      'coverImagePath': '',
      'visibility': 'private',
    });
  });

  test(
    'omits whitespace playlist description when updating playlist',
    () async {
      final httpClient = _FakeHttpClient(
        responses: {
          '/playlists/7': const HttpResponse(
            statusCode: 200,
            response: {
              'id': 7,
              'userId': 10,
              'name': 'Road',
              'description': '',
              'coverImagePath': '',
              'visibility': 'public',
              'trackCount': 0,
              'system': false,
              'isFavorites': false,
            },
          ),
        },
      );
      final storage = EsketitRestApiPlaylistsStorage(
        httpClient: httpClient,
        baseUri: Uri.parse('http://localhost:8080/api/'),
      );

      final playlist = await storage.updatePlaylist(
        playlistId: 7,
        input: const PlaylistUpsertInput(
          name: 'Road',
          description: '   ',
          coverImagePath: '',
          visibility: PlaylistVisibility.public,
        ),
      );

      expect(playlist.description, '');
      expect(httpClient.requestedPaths, ['/playlists/7']);
      expect(httpClient.bodies.single, {
        'name': 'Road',
        'coverImagePath': '',
        'visibility': 'public',
      });
    },
  );

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
                  'coverImagePath': '/api/album-covers/cover.jpg',
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
      expect(
        (details.tracks.single.image as HttpFile).uri,
        Uri.parse('http://localhost:8080/api/album-covers/cover.jpg'),
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

  test('uploads playlist cover as multipart file field', () async {
    final httpClient = _FakeHttpClient(
      responses: {
        '/playlists/7/cover': const HttpResponse(
          statusCode: 200,
          response: {
            'id': 7,
            'userId': 10,
            'name': 'Road',
            'description': 'Driving playlist',
            'coverImagePath': '/api/album-covers/generated.jpg',
            'visibility': 'private',
            'trackCount': 0,
            'system': false,
            'isFavorites': false,
          },
        ),
      },
    );
    final storage = EsketitRestApiPlaylistsStorage(
      httpClient: httpClient,
      baseUri: Uri.parse('http://localhost:8080/api/'),
    );

    final playlist = await storage.uploadPlaylistCover(
      playlistId: 7,
      input: const PlaylistCoverUploadInput(
        fileName: 'cover.png',
        bytes: [1, 2, 3],
      ),
    );

    expect(
      playlist.coverImagePath,
      'http://localhost:8080/api/album-covers/generated.jpg',
    );
    expect(httpClient.requestedPaths, ['/playlists/7/cover']);
    expect(httpClient.multipartFiles.single.fieldName, 'file');
    expect(httpClient.multipartFiles.single.fileName, 'cover.png');
    expect(httpClient.multipartFiles.single.bytes, [1, 2, 3]);
  });

  test(
    'resolves playlist track author photo URLs from authors response',
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
              'coverImagePath': '',
              'visibility': 'public',
              'trackCount': 1,
              'system': false,
              'isFavorites': false,
            },
          ),
          '/authors': const HttpResponse(
            statusCode: 200,
            response: [
              {
                'id': 1,
                'currentName': 'Artist Name',
                'photos': ['/api/author-photos/artist.jpg'],
              },
            ],
          ),
          '/public/playlists/7/tracks?page=1&pageSize=100': const HttpResponse(
            statusCode: 200,
            response: {
              'items': [
                {
                  'id': 123,
                  'name': 'Track name',
                  'authorIds': [1],
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

      expect(
        details.tracks.single.authors.single.primaryPhotoUrl,
        'http://localhost:8080/api/author-photos/artist.jpg',
      );
    },
  );
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.responses});

  final Map<String, HttpResponse> responses;
  final List<String> requestedPaths = <String>[];
  final List<Object?> bodies = <Object?>[];
  final List<MultipartFileData> multipartFiles = <MultipartFileData>[];

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
  }) async {
    requestedPaths.add(path);
    bodies.add(body);

    return responses[path] ??
        const HttpResponse(statusCode: 404, response: 'not found');
  }

  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  }) async {
    requestedPaths.add(path);
    multipartFiles.add(file);

    return responses[path] ??
        const HttpResponse(statusCode: 404, response: 'not found');
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    requestedPaths.add(path);
    bodies.add(body);

    return responses[path] ??
        const HttpResponse(statusCode: 404, response: 'not found');
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
