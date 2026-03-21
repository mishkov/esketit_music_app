import 'dart:convert';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';

class EsketitRestApiPlaylistsStorage implements PlaylistsStorage {
  const EsketitRestApiPlaylistsStorage({
    required HttpClient httpClient,
    required Uri baseUri,
  }) : _httpClient = httpClient,
       _baseUri = baseUri;

  final HttpClient _httpClient;
  final Uri _baseUri;

  @override
  Future<List<Playlist>> getPlaylists() async {
    final playlists = <Playlist>[];
    var page = 1;
    var totalPages = 1;

    do {
      final response = await _httpClient.get(
        Uri(
          path: '/playlists',
          queryParameters: {'page': '$page', 'pageSize': '100'},
        ).toString(),
      );
      _throwIfNotSuccess(response, '/playlists');

      final body = _decodeJsonMap(response.response, path: '/playlists');
      playlists.addAll(
        ((body['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_parsePlaylist),
      );
      totalPages = _asInt(body['totalPages']) ?? 1;
      page += 1;
    } while (page <= totalPages);

    return playlists;
  }

  @override
  Future<Playlist> getPlaylist({required int playlistId}) async {
    final path = '/playlists/$playlistId';
    final response = await _httpClient.get(path);
    _throwIfNotSuccess(response, path);
    return _parsePlaylist(_decodeJsonMap(response.response, path: path));
  }

  @override
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) async {
    final response = await _httpClient.post(
      '/playlists',
      body: _serializeUpsertInput(input),
    );
    _throwIfNotSuccess(response, '/playlists');
    return _parsePlaylist(
      _decodeJsonMap(response.response, path: '/playlists'),
    );
  }

  @override
  Future<Playlist> updatePlaylist({
    required int playlistId,
    required PlaylistUpsertInput input,
  }) async {
    final path = '/playlists/$playlistId';
    final response = await _httpClient.put(
      path,
      body: _serializeUpsertInput(input),
    );
    _throwIfNotSuccess(response, path);
    return _parsePlaylist(_decodeJsonMap(response.response, path: path));
  }

  @override
  Future<void> deletePlaylist({required int playlistId}) async {
    final path = '/playlists/$playlistId';
    final response = await _httpClient.delete(path);
    _throwIfNotSuccess(response, path);
  }

  @override
  Future<List<Track>> getPlaylistTracks({required int playlistId}) async {
    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');
    final authorsById = _parseAuthorsById(authorsResponse.response);

    final tracks = <Track>[];
    var page = 1;
    var totalPages = 1;

    do {
      final path = Uri(
        path: '/playlists/$playlistId/tracks',
        queryParameters: {'page': '$page', 'pageSize': '100'},
      ).toString();
      final response = await _httpClient.get(path);
      _throwIfNotSuccess(response, '/playlists/$playlistId/tracks');

      final body = _decodeJsonMap(response.response, path: path);
      tracks.addAll(
        ((body['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((item) => _parseTrack(item, authorsById: authorsById)),
      );
      totalPages = _asInt(body['totalPages']) ?? 1;
      page += 1;
    } while (page <= totalPages);

    return tracks;
  }

  @override
  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    final path = '/playlists/$playlistId/tracks/order';
    final response = await _httpClient.put(path, body: {'trackIds': trackIds});
    _throwIfNotSuccess(response, path);
  }

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) async {
    final path = '/tracks/$trackId/playlists';
    final response = await _httpClient.post(
      path,
      body: {'playlistIds': playlistIds},
    );
    _throwIfNotSuccess(response, path);
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  }) async {
    final path = '/tracks/$trackId/playlists/$playlistId';
    final response = await _httpClient.delete(path);
    _throwIfNotSuccess(response, path);
  }

  @override
  Future<void> addTrackToFavorites({required int trackId}) async {
    final path = '/tracks/$trackId/favorite';
    final response = await _httpClient.put(path);
    _throwIfNotSuccess(response, path);
  }

  @override
  Future<void> removeTrackFromFavorites({required int trackId}) async {
    final path = '/tracks/$trackId/favorite';
    final response = await _httpClient.delete(path);
    _throwIfNotSuccess(response, path);
  }

  Playlist _parsePlaylist(Map<String, dynamic> item) {
    return Playlist(
      id: _asInt(item['id']) ?? 0,
      userId: _asInt(item['userId']) ?? 0,
      name: (item['name'] as String?) ?? '',
      description: (item['description'] as String?) ?? '',
      coverImagePath: _resolveImagePath(
        (item['coverImagePath'] as String?) ?? '',
      ),
      visibility: _parseVisibility(item['visibility'] as String?),
      trackCount: _asInt(item['trackCount']) ?? 0,
      system: (item['system'] as bool?) ?? false,
      isFavorites: (item['isFavorites'] as bool?) ?? false,
    );
  }

  Track _parseTrack(
    Map<String, dynamic> item, {
    required Map<int, Author> authorsById,
  }) {
    final authorIds = ((item['authorIds'] as List?) ?? const [])
        .map(_asInt)
        .whereType<int>();

    return Track(
      id: _asInt(item['id']) ?? 0,
      name: (item['name'] as String?) ?? '',
      authors: authorIds
          .map(
            (authorId) =>
                authorsById[authorId] ??
                Author(
                  id: authorId,
                  currentName: 'Author #$authorId',
                  photos: const [],
                ),
          )
          .toList(growable: false),
      addionalInfo: const [],
      file: HttpFile(
        uri: _resolveSongUri((item['audioFilePath'] as String?) ?? ''),
      ),
      image: HttpFile(uri: Uri.parse('')),
      isFavorite: (item['isFavorite'] as bool?) ?? false,
      isAvailable: (item['isAvailable'] as bool?) ?? true,
    );
  }

  Map<String, Object?> _serializeUpsertInput(PlaylistUpsertInput input) {
    return {
      'name': input.name,
      'description': input.description,
      'coverImagePath': input.coverImagePath,
      'visibility': input.visibility.name,
    };
  }

  PlaylistVisibility _parseVisibility(String? value) {
    return PlaylistVisibility.values.firstWhere(
      (visibility) => visibility.name == value,
      orElse: () => PlaylistVisibility.private,
    );
  }

  String _resolveImagePath(String value) {
    if (value.isEmpty) {
      return value;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    return _baseUri.resolve(value).toString();
  }

  Uri _resolveSongUri(String audioFilePath) {
    final parsed = Uri.tryParse(audioFilePath);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    if (audioFilePath.isEmpty) {
      return Uri();
    }

    return _baseUri.resolve('songs/${Uri.encodeComponent(audioFilePath)}');
  }

  static void _throwIfNotSuccess(HttpResponse response, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedAppError(path: path, responseBody: response.response);
    }
    if (response.statusCode == 403) {
      throw ForbiddenAppError(path: path, responseBody: response.response);
    }

    throw HttpAppError(
      message: 'Request failed',
      path: path,
      statusCode: response.statusCode,
      responseBody: response.response,
    );
  }

  static Map<String, dynamic> _decodeJsonMap(
    Object? body, {
    required String path,
  }) {
    final decoded = _coerceJson(body);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object response for $path');
    }

    return decoded;
  }

  static Object? _coerceJson(Object? body) {
    if (body is String) {
      return jsonDecode(body);
    }
    return body;
  }

  static Map<int, Author> _parseAuthorsById(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw const FormatException(
        'Expected /authors response to be a JSON list',
      );
    }

    final result = <int, Author>{};
    for (final item in body.whereType<Map<String, dynamic>>()) {
      final id = _asInt(item['id']);
      if (id == null) {
        continue;
      }

      result[id] = Author(
        id: id,
        currentName: (item['currentName'] as String?) ?? '',
        photos: ((item['photos'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
    }
    return result;
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
