import 'dart:convert';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';

class EsketitRestApiTracksStorage implements TracksStorage {
  final HttpClient _httpClient;

  const EsketitRestApiTracksStorage({required HttpClient httpClient})
    : _httpClient = httpClient;

  @override
  Future<List<Track>> getTracks({
    required int tracksPerPage,
    Track? lastFetchedTrack,
  }) async {
    final tracksResponse = await _httpClient.get('/tracks');
    _throwIfNotSuccess(tracksResponse, '/tracks');

    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');

    final authorsById = _parseAuthorsById(authorsResponse.response);
    final tracks = _parseTracks(tracksResponse.response, authorsById);

    final startIndex = _resolveStartIndex(tracks, lastFetchedTrack);
    final safePageSize = tracksPerPage < 0 ? 0 : tracksPerPage;
    final endIndex = (startIndex + safePageSize)
        .clamp(0, tracks.length)
        .toInt();
    return tracks.sublist(startIndex, endIndex);
  }

  static int _resolveStartIndex(List<Track> tracks, Track? lastFetchedTrack) {
    if (lastFetchedTrack == null) {
      return 0;
    }

    final lastIndex = tracks.lastIndexOf(lastFetchedTrack);
    if (lastIndex == -1) {
      return 0;
    }

    return lastIndex + 1;
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

  static Map<int, Author> _parseAuthorsById(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      // TODO: throw AppError or it's custom subclass
      throw const FormatException(
        'Expected /authors response to be a JSON list',
      );
    }

    final result = <int, Author>{};
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
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

  static List<Track> _parseTracks(
    Object? responseBody,
    Map<int, Author> authorsById,
  ) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      // TODO: throw AppError or it's custom subclass
      throw const FormatException(
        'Expected /tracks response to be a JSON list',
      );
    }

    final tracks = <Track>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final name = (item['name'] as String?) ?? '';
      final audioFilePath = (item['audioFilePath'] as String?) ?? '';
      final albumImagePath = (item['albumImagePath'] as String?) ?? '';
      final authorIds = item['authorIds'];

      final authors = <Author>[];
      if (authorIds is List) {
        for (final authorIdValue in authorIds) {
          final authorId = _asInt(authorIdValue);
          if (authorId == null) {
            continue;
          }

          final author = authorsById[authorId];
          if (author != null) {
            authors.add(author);
            continue;
          }

          authors.add(
            Author(
              id: authorId,
              currentName: 'Author #$authorId',
              photos: const [],
            ),
          );
        }
      }

      tracks.add(
        Track(
          id: _asInt(item['id']) ?? 0,
          name: name,
          authors: authors,
          addionalInfo: const [],
          file: HttpFile(uri: Uri.parse(audioFilePath)),
          image: HttpFile(uri: Uri.parse(albumImagePath)),
          isFavorite: (item['isFavorite'] as bool?) ?? false,
          isAvailable: (item['isAvailable'] as bool?) ?? true,
        ),
      );
    }

    return tracks;
  }

  static Object? _coerceJson(Object? body) {
    if (body is String) {
      return jsonDecode(body);
    }
    return body;
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
