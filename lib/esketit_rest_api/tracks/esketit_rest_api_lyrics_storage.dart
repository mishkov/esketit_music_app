import 'dart:convert';

import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';

class EsketitRestApiLyricsStorage implements LyricsStorage {
  const EsketitRestApiLyricsStorage({required HttpClient httpClient})
    : _httpClient = httpClient;

  final HttpClient _httpClient;

  @override
  Future<TrackLyrics?> getTrackLyrics({required int trackId}) async {
    final path = '/tracks/$trackId/lyrics';
    final response = await _httpClient.get(path);

    if (response.statusCode == 404) {
      return null;
    }

    _throwIfNotSuccess(response, path);

    final body = _coerceJson(response.response);
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected /tracks/{id}/lyrics response to be a JSON object',
      );
    }

    return _parseTrackLyrics(body);
  }

  static TrackLyrics _parseTrackLyrics(Map<String, dynamic> body) {
    return TrackLyrics(
      trackId: _asInt(body['trackId']) ?? 0,
      type: _parseTrackLyricsType(body['type']),
      languageCode: body['languageCode'] as String?,
      isVerified: body['isVerified'] as bool? ?? false,
      source: body['source'] as String?,
      plainText: body['plainText'] as String?,
      lines: ((body['lines'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (line) => SyncedTrackLyricsLine(
              startMs: _asInt(line['startMs']) ?? 0,
              endMs: _asInt(line['endMs']),
              text: (line['text'] as String?) ?? '',
            ),
          )
          .toList(growable: false),
    );
  }

  static TrackLyricsType _parseTrackLyricsType(Object? value) {
    return switch (value) {
      'synced' => TrackLyricsType.synced,
      _ => TrackLyricsType.plain,
    };
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
