import 'dart:async';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/unassigned_layer/downloads/downloads_database.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/downloads/downloads_storage.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:sqflite/sqflite.dart';

typedef LocalDownloadPathResolver = String Function(String relativePath);

class SqfliteDownloadsStorage implements DownloadsStorage {
  SqfliteDownloadsStorage({
    required Database database,
    LocalDownloadPathResolver? localPathResolver,
    DateTime Function()? clock,
  }) : _database = database,
       _localPathResolver = localPathResolver ?? _identityPathResolver,
       _clock = clock ?? DateTime.now;

  static Future<SqfliteDownloadsStorage> open({
    required String databasePath,
    DatabaseFactory? databaseFactory,
    LocalDownloadPathResolver? localPathResolver,
    DateTime Function()? clock,
  }) async {
    final database = await DownloadsDatabase.open(
      path: databasePath,
      factory: databaseFactory,
    );

    return SqfliteDownloadsStorage(
      database: database,
      localPathResolver: localPathResolver,
      clock: clock,
    );
  }

  final Database _database;
  final LocalDownloadPathResolver _localPathResolver;
  final DateTime Function() _clock;
  final StreamController<int> _revisions = StreamController<int>.broadcast();
  int _revision = 0;

  Future<void> close() async {
    await _revisions.close();
    await _database.close();
  }

  @override
  Future<void> enqueueTrack({
    required DownloadTrackSnapshot snapshot,
    DownloadReason? reason,
  }) async {
    _validateSnapshot(snapshot);
    final effectiveReason = reason ?? DownloadReason.track(snapshot.track.id);
    if (effectiveReason.type == DownloadReasonType.track &&
        effectiveReason.entityId != snapshot.track.id) {
      throw ArgumentError.value(
        effectiveReason.entityId,
        'reason.entityId',
        'A direct reason must use the same track ID',
      );
    }

    await _database.transaction((transaction) async {
      await _upsertTrackSnapshot(transaction, snapshot);
      await _insertReference(
        transaction,
        trackId: snapshot.track.id,
        reason: effectiveReason,
      );
      await _enqueueJobIfNeeded(transaction, snapshot.track.id);
    });
    _emitRevision();
  }

  @override
  Future<void> enqueueAlbum(DownloadAlbumSnapshot snapshot) async {
    for (final trackSnapshot in snapshot.tracks) {
      _validateSnapshot(trackSnapshot);
      if (trackSnapshot.track.albumId != null &&
          trackSnapshot.track.albumId != snapshot.album.id) {
        throw ArgumentError(
          'Track ${trackSnapshot.track.id} belongs to album '
          '${trackSnapshot.track.albumId}, not ${snapshot.album.id}',
        );
      }
    }

    await _database.transaction((transaction) async {
      await _upsertAlbum(transaction, snapshot.album);
      for (final trackSnapshot in snapshot.tracks) {
        await _upsertTrackSnapshot(
          transaction,
          DownloadTrackSnapshot(
            track: trackSnapshot.track,
            lyrics: trackSnapshot.lyrics,
            album: snapshot.album,
          ),
        );
        await _insertReference(
          transaction,
          trackId: trackSnapshot.track.id,
          reason: DownloadReason.album(snapshot.album.id),
        );
        await _enqueueJobIfNeeded(transaction, trackSnapshot.track.id);
      }
    });
    _emitRevision();
  }

  @override
  Future<void> enqueuePlaylist(DownloadPlaylistSnapshot snapshot) async {
    for (final trackSnapshot in snapshot.tracks) {
      _validateSnapshot(trackSnapshot);
    }

    await _database.transaction((transaction) async {
      final existingPlaylist = await transaction.query(
        'download_playlists',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [snapshot.playlist.id],
        limit: 1,
      );
      final isNewSnapshot = existingPlaylist.isEmpty;
      if (isNewSnapshot) {
        await _insertPlaylist(transaction, snapshot.playlist);
      }

      final durableTrackIds = isNewSnapshot
          ? snapshot.tracks.map((item) => item.track.id).toList(growable: false)
          : (await transaction.query(
              'download_playlist_tracks',
              columns: const ['track_id'],
              where: 'playlist_id = ?',
              whereArgs: [snapshot.playlist.id],
              orderBy: 'position',
            )).map((row) => row['track_id']! as int).toList(growable: false);
      final durableTrackIdSet = durableTrackIds.toSet();
      for (final trackSnapshot in snapshot.tracks.where(
        (item) => durableTrackIdSet.contains(item.track.id),
      )) {
        await _upsertTrackSnapshot(transaction, trackSnapshot);
      }

      if (isNewSnapshot) {
        for (var index = 0; index < snapshot.tracks.length; index += 1) {
          await transaction.insert('download_playlist_tracks', {
            'playlist_id': snapshot.playlist.id,
            'position': index,
            'track_id': snapshot.tracks[index].track.id,
          });
        }
      }

      for (final trackId in durableTrackIds) {
        await _insertReference(
          transaction,
          trackId: trackId,
          reason: DownloadReason.playlist(snapshot.playlist.id),
        );
        await _enqueueJobIfNeeded(transaction, trackId);
      }
    });
    _emitRevision();
  }

  @override
  Future<void> cacheLyrics(DownloadLyricsSnapshot snapshot) async {
    if (snapshot.availability == DownloadLyricsAvailability.notFetched) {
      throw ArgumentError(
        'Only a fetched lyrics result can be added to the cache',
      );
    }
    await _database.transaction((transaction) async {
      final trackExists = await _rowExists(
        transaction,
        table: 'download_tracks',
        where: 'id = ?',
        whereArgs: [snapshot.trackId],
      );
      if (!trackExists) {
        throw StateError('Unknown download track ${snapshot.trackId}');
      }
      await _upsertLyrics(transaction, snapshot, replaceNotFetched: true);
    });
    _emitRevision();
  }

  Future<void> _upsertTrackSnapshot(
    DatabaseExecutor executor,
    DownloadTrackSnapshot snapshot,
  ) async {
    final track = snapshot.track;
    final album = snapshot.album;
    if (album != null) {
      if (track.albumId != null && track.albumId != album.id) {
        throw ArgumentError(
          'Track ${track.id} and its album snapshot disagree on album ID',
        );
      }
      await _upsertAlbum(executor, album);
    } else if (track.albumId != null) {
      await executor.rawInsert(
        '''
INSERT INTO download_albums (
  id, title, cover_asset_id, release_date_ms, is_published, snapshotted_at_ms
) VALUES (?, '', NULL, NULL, 0, ?)
ON CONFLICT(id) DO NOTHING
''',
        [track.albumId, _nowMilliseconds],
      );
    }

    for (final author in track.authors) {
      await _upsertAuthor(executor, author);
    }
    final imageAssetId = await _upsertAsset(
      executor,
      uri: _fileUri(track.image),
      kind: 'trackArtwork',
    );
    final remoteAudioUri = _fileUri(track.file)?.toString() ?? '';
    if (remoteAudioUri.isEmpty) {
      final existing = await executor.query(
        'download_tracks',
        columns: const ['audio_remote_uri'],
        where: 'id = ?',
        whereArgs: [track.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        throw ArgumentError('Track ${track.id} has no remote audio URI');
      }
    }

    await executor.rawInsert(
      '''
INSERT INTO download_tracks (
  id, album_id, name, audio_remote_uri, image_asset_id,
  is_favorite, is_disliked, is_available, created_at_ms, snapshotted_at_ms
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  album_id = excluded.album_id,
  name = excluded.name,
  audio_remote_uri = CASE
    WHEN excluded.audio_remote_uri = '' THEN download_tracks.audio_remote_uri
    ELSE excluded.audio_remote_uri
  END,
  image_asset_id = COALESCE(excluded.image_asset_id, download_tracks.image_asset_id),
  is_favorite = excluded.is_favorite,
  is_disliked = excluded.is_disliked,
  is_available = excluded.is_available,
  created_at_ms = COALESCE(excluded.created_at_ms, download_tracks.created_at_ms)
''',
      [
        track.id,
        track.albumId ?? album?.id,
        track.name,
        remoteAudioUri,
        imageAssetId,
        _boolToInt(track.isFavorite),
        _boolToInt(track.isDisliked),
        _boolToInt(track.isAvailable),
        track.createdAt?.millisecondsSinceEpoch,
        _nowMilliseconds,
      ],
    );

    await executor.delete(
      'download_track_authors',
      where: 'track_id = ?',
      whereArgs: [track.id],
    );
    for (var index = 0; index < track.authors.length; index += 1) {
      await executor.insert('download_track_authors', {
        'track_id': track.id,
        'position': index,
        'author_id': track.authors[index].id,
      });
    }
    await _replaceAdditionalInfo(
      executor,
      table: 'download_track_additional_info',
      ownerColumn: 'track_id',
      ownerId: track.id,
      values: track.addionalInfo,
    );
    await _upsertLyrics(executor, snapshot.lyrics);
  }

  Future<void> _upsertAlbum(DatabaseExecutor executor, Album album) async {
    for (final authorId in album.authorIds) {
      await executor.rawInsert(
        '''
INSERT INTO download_authors (id, current_name)
VALUES (?, ?)
ON CONFLICT(id) DO NOTHING
''',
        [authorId, 'Author #$authorId'],
      );
    }
    final coverAssetId = await _upsertAsset(
      executor,
      uri: _fileUri(album.coverImage),
      kind: 'albumArtwork',
    );
    await executor.rawInsert(
      '''
INSERT INTO download_albums (
  id, title, cover_asset_id, release_date_ms, is_published, snapshotted_at_ms
) VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  cover_asset_id = COALESCE(excluded.cover_asset_id, download_albums.cover_asset_id),
  release_date_ms = excluded.release_date_ms,
  is_published = excluded.is_published
''',
      [
        album.id,
        album.title,
        coverAssetId,
        album.releaseDate?.millisecondsSinceEpoch,
        _boolToInt(album.isPublished),
        _nowMilliseconds,
      ],
    );

    await executor.delete(
      'download_album_authors',
      where: 'album_id = ?',
      whereArgs: [album.id],
    );
    for (var index = 0; index < album.authorIds.length; index += 1) {
      await executor.insert('download_album_authors', {
        'album_id': album.id,
        'position': index,
        'author_id': album.authorIds[index],
      });
    }
    await executor.delete(
      'download_album_tracks',
      where: 'album_id = ?',
      whereArgs: [album.id],
    );
    for (var index = 0; index < album.trackIds.length; index += 1) {
      await executor.insert('download_album_tracks', {
        'album_id': album.id,
        'position': index,
        'track_id': album.trackIds[index],
      });
    }
    await _replaceAdditionalInfo(
      executor,
      table: 'download_album_additional_info',
      ownerColumn: 'album_id',
      ownerId: album.id,
      values: album.additionalInfo,
    );
  }

  Future<void> _upsertAuthor(DatabaseExecutor executor, Author author) async {
    await executor.rawInsert(
      '''
INSERT INTO download_authors (id, current_name)
VALUES (?, ?)
ON CONFLICT(id) DO UPDATE SET current_name = excluded.current_name
''',
      [author.id, author.currentName],
    );
    await executor.delete(
      'download_author_photos',
      where: 'author_id = ?',
      whereArgs: [author.id],
    );
    for (var index = 0; index < author.photos.length; index += 1) {
      final uri = Uri.tryParse(author.photos[index]);
      final assetId = await _upsertAsset(
        executor,
        uri: uri,
        kind: 'authorPhoto',
      );
      if (assetId == null) {
        continue;
      }
      await executor.insert('download_author_photos', {
        'author_id': author.id,
        'position': index,
        'asset_id': assetId,
      });
    }
  }

  Future<void> _insertPlaylist(
    DatabaseExecutor executor,
    Playlist playlist,
  ) async {
    final coverAssetId = await _upsertAsset(
      executor,
      uri: Uri.tryParse(playlist.coverImagePath),
      kind: 'playlistArtwork',
    );
    await executor.insert('download_playlists', {
      'id': playlist.id,
      'user_id': playlist.userId,
      'name': playlist.name,
      'description': playlist.description,
      'cover_asset_id': coverAssetId,
      'visibility': playlist.visibility.name,
      'track_count': playlist.trackCount,
      'system': _boolToInt(playlist.system),
      'kind': playlist.kind.name,
      'share_token': playlist.shareToken,
      'snapshotted_at_ms': _nowMilliseconds,
    });
  }

  Future<int?> _upsertAsset(
    DatabaseExecutor executor, {
    required Uri? uri,
    required String kind,
  }) async {
    if (uri == null || uri.toString().isEmpty) {
      return null;
    }
    await executor.rawInsert(
      '''
INSERT INTO download_assets (remote_uri, kind)
VALUES (?, ?)
ON CONFLICT(remote_uri) DO NOTHING
''',
      [uri.toString(), kind],
    );
    final rows = await executor.query(
      'download_assets',
      columns: const ['id'],
      where: 'remote_uri = ?',
      whereArgs: [uri.toString()],
      limit: 1,
    );

    return rows.single['id']! as int;
  }

  Future<void> _replaceAdditionalInfo(
    DatabaseExecutor executor, {
    required String table,
    required String ownerColumn,
    required int ownerId,
    required List<TrackInfo> values,
  }) async {
    await executor.delete(
      table,
      where: '$ownerColumn = ?',
      whereArgs: [ownerId],
    );
    var position = 0;
    for (final value in values) {
      if (value is! TextTrackInfo) {
        continue;
      }
      await executor.insert(table, {
        ownerColumn: ownerId,
        'position': position,
        'kind': 'text',
        'title': value.title,
        'text': value.text,
      });
      position += 1;
    }
  }

  Future<void> _upsertLyrics(
    DatabaseExecutor executor,
    DownloadLyricsSnapshot snapshot, {
    bool replaceNotFetched = false,
  }) async {
    if (snapshot.lyrics != null &&
        snapshot.lyrics!.trackId != snapshot.trackId) {
      throw ArgumentError('Lyrics and snapshot track IDs do not match');
    }
    if (snapshot.availability == DownloadLyricsAvailability.notFetched &&
        !replaceNotFetched) {
      final existing = await _rowExists(
        executor,
        table: 'download_track_lyrics',
        where: 'track_id = ?',
        whereArgs: [snapshot.trackId],
      );
      if (existing) {
        return;
      }
    }

    final lyrics = snapshot.lyrics;
    await executor.rawInsert(
      '''
INSERT INTO download_track_lyrics (
  track_id, availability, lyrics_type, language_code,
  is_verified, source, plain_text
) VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(track_id) DO UPDATE SET
  availability = excluded.availability,
  lyrics_type = excluded.lyrics_type,
  language_code = excluded.language_code,
  is_verified = excluded.is_verified,
  source = excluded.source,
  plain_text = excluded.plain_text
''',
      [
        snapshot.trackId,
        snapshot.availability.name,
        lyrics?.type.name,
        lyrics?.languageCode,
        lyrics == null ? null : _boolToInt(lyrics.isVerified),
        lyrics?.source,
        lyrics?.plainText,
      ],
    );
    await executor.delete(
      'download_lyrics_lines',
      where: 'track_id = ?',
      whereArgs: [snapshot.trackId],
    );
    if (lyrics == null) {
      return;
    }
    for (var index = 0; index < lyrics.lines.length; index += 1) {
      final line = lyrics.lines[index];
      await executor.insert('download_lyrics_lines', {
        'track_id': snapshot.trackId,
        'position': index,
        'start_ms': line.startMs,
        'end_ms': line.endMs,
        'text': line.text,
      });
    }
  }

  Future<void> _insertReference(
    DatabaseExecutor executor, {
    required int trackId,
    required DownloadReason reason,
  }) {
    return executor
        .insert('download_references', {
          'track_id': trackId,
          'reason_type': reason.type.name,
          'reason_id': reason.entityId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore)
        .then((_) {});
  }

  Future<void> _enqueueJobIfNeeded(
    DatabaseExecutor executor,
    int trackId,
  ) async {
    final isDownloaded = await _rowExists(
      executor,
      table: 'download_track_files',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
    if (isDownloaded) {
      return;
    }
    final hasActiveJob = await _rowExists(
      executor,
      table: 'download_jobs',
      where:
          "track_id = ? AND state IN ('queued', 'downloading', 'waitingToRetry')",
      whereArgs: [trackId],
    );
    if (hasActiveJob) {
      return;
    }

    await executor.update(
      'download_jobs',
      {'failure_acknowledged_at_ms': _nowMilliseconds},
      where:
          "track_id = ? AND state = 'failed' "
          'AND failure_acknowledged_at_ms IS NULL',
      whereArgs: [trackId],
    );

    final batchId = await _ensureActiveBatch(executor);
    await executor.insert('download_jobs', {
      'batch_id': batchId,
      'track_id': trackId,
      'state': DownloadJobState.queued.name,
      'enqueued_at_ms': _nowMilliseconds,
    });
  }

  Future<int> _ensureActiveBatch(DatabaseExecutor executor) async {
    final active = await executor.query(
      'download_batches',
      columns: const ['id'],
      where: 'ended_at_ms IS NULL',
      limit: 1,
    );
    if (active.isNotEmpty) {
      return active.single['id']! as int;
    }

    return executor.insert('download_batches', {
      'created_at_ms': _nowMilliseconds,
    });
  }

  @override
  Stream<DownloadQueueSnapshot> watchQueue() => _watch(getQueue);

  @override
  Future<DownloadQueueSnapshot> getQueue() async {
    final currentRows = await _database.rawQuery('''
SELECT jobs.*, tracks.name AS track_name
FROM download_jobs AS jobs
INNER JOIN download_tracks AS tracks ON tracks.id = jobs.track_id
WHERE jobs.state = 'downloading'
ORDER BY jobs.id
LIMIT 1
''');
    final queuedRows = await _database.rawQuery('''
SELECT jobs.*, tracks.name AS track_name
FROM download_jobs AS jobs
INNER JOIN download_tracks AS tracks ON tracks.id = jobs.track_id
WHERE jobs.state IN ('queued', 'waitingToRetry')
ORDER BY jobs.id
''');
    final failureRows = await _database.rawQuery('''
SELECT jobs.*, tracks.name AS track_name
FROM download_jobs AS jobs
INNER JOIN download_tracks AS tracks ON tracks.id = jobs.track_id
WHERE jobs.state = 'failed' AND jobs.failure_acknowledged_at_ms IS NULL
ORDER BY jobs.id
''');

    return DownloadQueueSnapshot(
      current: currentRows.isEmpty ? null : _jobFromRow(currentRows.single),
      queued: queuedRows.map(_jobFromRow).toList(growable: false),
      failures: failureRows.map(_jobFromRow).toList(growable: false),
    );
  }

  @override
  Future<DownloadJobSnapshot?> claimNextJob({required DateTime now}) async {
    final claimed = await _database.transaction((transaction) async {
      final hasCurrent = await _rowExists(
        transaction,
        table: 'download_jobs',
        where: "state = 'downloading'",
        whereArgs: const [],
      );
      if (hasCurrent) {
        return null;
      }

      final rows = await transaction.rawQuery('''
SELECT jobs.*, tracks.name AS track_name
FROM download_jobs AS jobs
INNER JOIN download_tracks AS tracks ON tracks.id = jobs.track_id
WHERE jobs.state IN ('queued', 'waitingToRetry')
ORDER BY jobs.id
LIMIT 1
''');
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.single;
      final nextAttemptMilliseconds = row['next_attempt_at_ms'] as int?;
      if (nextAttemptMilliseconds != null &&
          nextAttemptMilliseconds > now.toUtc().millisecondsSinceEpoch) {
        return null;
      }

      final jobId = row['id']! as int;
      final changed = await transaction.update(
        'download_jobs',
        {
          'state': DownloadJobState.downloading.name,
          'started_at_ms': now.toUtc().millisecondsSinceEpoch,
          'attempt_count': (row['attempt_count']! as int) + 1,
          'next_attempt_at_ms': null,
          'failure_kind': null,
          'failure_message': null,
        },
        where: "id = ? AND state IN ('queued', 'waitingToRetry')",
        whereArgs: [jobId],
      );
      if (changed != 1) {
        return null;
      }
      final updatedRows = await transaction.rawQuery(
        '''
SELECT jobs.*, tracks.name AS track_name
FROM download_jobs AS jobs
INNER JOIN download_tracks AS tracks ON tracks.id = jobs.track_id
WHERE jobs.id = ?
''',
        [jobId],
      );

      return _jobFromRow(updatedRows.single);
    });
    if (claimed != null) {
      _emitRevision();
    }

    return claimed;
  }

  @override
  Future<void> recoverInterruptedJobs() async {
    final changed = await _database.update('download_jobs', {
      'state': DownloadJobState.queued.name,
      'started_at_ms': null,
      'next_attempt_at_ms': null,
    }, where: "state = 'downloading'");
    if (changed > 0) {
      _emitRevision();
    }
  }

  @override
  Future<void> updateJobProgress({
    required int jobId,
    required int receivedBytes,
    required int? totalBytes,
    String? temporaryRelativePath,
    String? entityTag,
    String? lastModified,
  }) async {
    if (receivedBytes < 0 || (totalBytes != null && totalBytes < 0)) {
      throw ArgumentError('Download byte counts cannot be negative');
    }
    if (temporaryRelativePath != null) {
      _validateRelativePath(temporaryRelativePath);
    }
    final values = <String, Object?>{
      'received_bytes': receivedBytes,
      'total_bytes': totalBytes,
      'temporary_relative_path': ?temporaryRelativePath,
      'entity_tag': ?entityTag,
      'last_modified': ?lastModified,
    };
    final changed = await _database.update(
      'download_jobs',
      values,
      where: "id = ? AND state = 'downloading'",
      whereArgs: [jobId],
    );
    if (changed != 1) {
      throw StateError('Download job $jobId is not active');
    }
    _emitRevision();
  }

  @override
  Future<void> scheduleJobRetry({
    required int jobId,
    required DateTime nextAttemptAt,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  }) async {
    final changed = await _database.update(
      'download_jobs',
      {
        'state': DownloadJobState.waitingToRetry.name,
        'started_at_ms': null,
        'next_attempt_at_ms': nextAttemptAt.toUtc().millisecondsSinceEpoch,
        'failure_kind': failureKind.name,
        'failure_message': failureMessage,
      },
      where: "id = ? AND state = 'downloading'",
      whereArgs: [jobId],
    );
    if (changed != 1) {
      throw StateError('Download job $jobId is not active');
    }
    _emitRevision();
  }

  @override
  Future<void> completeJob({
    required int jobId,
    required String audioRelativePath,
    required int audioByteCount,
    Map<Uri, String> cachedArtworkRelativePaths = const {},
    String? entityTag,
    String? lastModified,
  }) async {
    _validateRelativePath(audioRelativePath);
    if (audioByteCount < 0) {
      throw ArgumentError.value(
        audioByteCount,
        'audioByteCount',
        'Must not be negative',
      );
    }
    for (final relativePath in cachedArtworkRelativePaths.values) {
      _validateRelativePath(relativePath);
    }

    await _database.transaction((transaction) async {
      final jobs = await transaction.query(
        'download_jobs',
        columns: const ['batch_id', 'track_id'],
        where: "id = ? AND state = 'downloading'",
        whereArgs: [jobId],
        limit: 1,
      );
      if (jobs.isEmpty) {
        throw StateError('Download job $jobId is not active');
      }
      final job = jobs.single;
      final trackId = job['track_id']! as int;
      final batchId = job['batch_id']! as int;
      await transaction.rawInsert(
        '''
INSERT INTO download_track_files (
  track_id, audio_relative_path, byte_count, downloaded_at_ms,
  entity_tag, last_modified
) VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(track_id) DO UPDATE SET
  audio_relative_path = excluded.audio_relative_path,
  byte_count = excluded.byte_count,
  downloaded_at_ms = excluded.downloaded_at_ms,
  entity_tag = excluded.entity_tag,
  last_modified = excluded.last_modified
''',
        [
          trackId,
          audioRelativePath,
          audioByteCount,
          _nowMilliseconds,
          entityTag,
          lastModified,
        ],
      );
      for (final entry in cachedArtworkRelativePaths.entries) {
        await transaction.update(
          'download_assets',
          {'local_relative_path': entry.value, 'state': 'available'},
          where: 'remote_uri = ?',
          whereArgs: [entry.key.toString()],
        );
      }
      await transaction.delete(
        'download_jobs',
        where: 'id = ?',
        whereArgs: [jobId],
      );
      await transaction.update(
        'download_jobs',
        {'failure_acknowledged_at_ms': _nowMilliseconds},
        where:
            "track_id = ? AND state = 'failed' "
            'AND failure_acknowledged_at_ms IS NULL',
        whereArgs: [trackId],
      );
      await _finishBatchIfIdle(transaction, batchId);
    });
    _emitRevision();
  }

  @override
  Future<DownloadRemovalResult> failJob({
    required int jobId,
    required DownloadFailureKind failureKind,
    String? failureMessage,
  }) async {
    final result = await _database.transaction((transaction) async {
      final jobs = await transaction.query(
        'download_jobs',
        columns: const ['batch_id', 'track_id', 'temporary_relative_path'],
        where:
            "id = ? AND state IN ('queued', 'downloading', 'waitingToRetry')",
        whereArgs: [jobId],
        limit: 1,
      );
      if (jobs.isEmpty) {
        throw StateError('Download job $jobId is not pending');
      }
      final job = jobs.single;
      final batchId = job['batch_id']! as int;
      final temporaryPath = job['temporary_relative_path'] as String?;
      await transaction.update(
        'download_jobs',
        {
          'state': DownloadJobState.failed.name,
          'started_at_ms': null,
          'next_attempt_at_ms': null,
          'temporary_relative_path': null,
          'failure_kind': failureKind.name,
          'failure_message': failureMessage,
          'failure_acknowledged_at_ms': null,
        },
        where: 'id = ?',
        whereArgs: [jobId],
      );
      final paths = <String>[];
      if (temporaryPath != null) {
        paths.add(temporaryPath);
        await _enqueuePendingDeletion(transaction, temporaryPath);
      }
      await _finishBatchIfIdle(transaction, batchId);

      return DownloadRemovalResult(
        removedTrackIds: const [],
        relativePathsToDelete: paths,
      );
    });
    _emitRevision();

    return result;
  }

  @override
  Future<void> acknowledgeFailures() async {
    final changed = await _database.update(
      'download_jobs',
      {'failure_acknowledged_at_ms': _nowMilliseconds},
      where: "state = 'failed' AND failure_acknowledged_at_ms IS NULL",
    );
    if (changed > 0) {
      _emitRevision();
    }
  }

  Future<void> _finishBatchIfIdle(
    DatabaseExecutor executor,
    int batchId,
  ) async {
    final hasWork = await _rowExists(
      executor,
      table: 'download_jobs',
      where:
          "batch_id = ? AND state IN ('queued', 'downloading', 'waitingToRetry')",
      whereArgs: [batchId],
    );
    if (!hasWork) {
      await executor.update(
        'download_batches',
        {'ended_at_ms': _nowMilliseconds},
        where: 'id = ? AND ended_at_ms IS NULL',
        whereArgs: [batchId],
      );
    }
  }

  DownloadJobSnapshot _jobFromRow(Map<String, Object?> row) {
    return DownloadJobSnapshot(
      id: row['id']! as int,
      batchId: row['batch_id']! as int,
      trackId: row['track_id']! as int,
      trackName: row['track_name']! as String,
      state: DownloadJobState.values.byName(row['state']! as String),
      enqueuedAt: _dateTimeFromMilliseconds(row['enqueued_at_ms'])!,
      attemptCount: row['attempt_count']! as int,
      receivedBytes: row['received_bytes']! as int,
      totalBytes: row['total_bytes'] as int?,
      nextAttemptAt: _dateTimeFromMilliseconds(row['next_attempt_at_ms']),
      temporaryRelativePath: row['temporary_relative_path'] as String?,
      entityTag: row['entity_tag'] as String?,
      lastModified: row['last_modified'] as String?,
      failureKind: _failureKindFromName(row['failure_kind'] as String?),
      failureMessage: row['failure_message'] as String?,
    );
  }

  @override
  Future<DownloadTrackSnapshot?> getTrackSnapshot({
    required int trackId,
  }) async {
    final track = await _loadTrack(
      _database,
      trackId: trackId,
      requireDownloaded: false,
      useLocalFiles: false,
    );
    if (track == null) {
      return null;
    }
    final album = track.albumId == null
        ? null
        : await _loadAlbum(
            _database,
            albumId: track.albumId!,
            downloadedTracksOnly: false,
            useLocalFiles: false,
          );
    final lyrics =
        await getLyricsSnapshot(trackId: trackId) ??
        DownloadLyricsSnapshot.notFetched(trackId);

    return DownloadTrackSnapshot(track: track, album: album, lyrics: lyrics);
  }

  @override
  Future<List<Uri>> getPendingArtworkUris({required int trackId}) async {
    final rows = await _database.rawQuery(
      '''
SELECT DISTINCT assets.remote_uri
FROM download_assets AS assets
WHERE assets.state != 'available'
AND assets.id IN (
  SELECT tracks.image_asset_id
  FROM download_tracks AS tracks
  WHERE tracks.id = ?
  UNION
  SELECT photos.asset_id
  FROM download_track_authors AS track_authors
  INNER JOIN download_author_photos AS photos
    ON photos.author_id = track_authors.author_id
  WHERE track_authors.track_id = ?
  UNION
  SELECT albums.cover_asset_id
  FROM download_tracks AS tracks
  INNER JOIN download_albums AS albums ON albums.id = tracks.album_id
  WHERE tracks.id = ?
  UNION
  SELECT playlists.cover_asset_id
  FROM download_references AS refs
  INNER JOIN download_playlists AS playlists
    ON refs.reason_type = 'playlist' AND playlists.id = refs.reason_id
  WHERE refs.track_id = ?
)
ORDER BY assets.id
''',
      [trackId, trackId, trackId, trackId],
    );

    return rows
        .map((row) => Uri.tryParse(row['remote_uri']! as String))
        .whereType<Uri>()
        .toList(growable: false);
  }

  Stream<T> _watch<T>(Future<T> Function() reader) {
    return Stream<int>.multi((controller) {
      controller.add(_revision);
      final subscription = _revisions.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    }).asyncMap((_) => reader());
  }

  static DownloadFailureKind? _failureKindFromName(String? value) {
    if (value == null) {
      return null;
    }

    return DownloadFailureKind.values
        .where((kind) => kind.name == value)
        .firstOrNull;
  }

  static DateTime? _dateTimeFromMilliseconds(Object? value) {
    if (value is! int) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  static void _validateRelativePath(String value) {
    final uri = Uri.tryParse(value);
    final pathSegments = value.replaceAll('\\', '/').split('/');
    if (value.isEmpty ||
        value.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(value) ||
        (uri?.hasScheme ?? false) ||
        pathSegments.contains('..')) {
      throw ArgumentError.value(value, 'relativePath', 'Must be relative');
    }
  }

  Future<void> _enqueuePendingDeletion(
    DatabaseExecutor executor,
    String relativePath,
  ) async {
    _validateRelativePath(relativePath);
    await executor.insert('pending_file_deletions', {
      'relative_path': relativePath,
      'enqueued_at_ms': _nowMilliseconds,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<DownloadRemovalResult> removeTrack({required int trackId}) async {
    final result = await _database.transaction((transaction) async {
      await transaction.delete(
        'download_references',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );

      return _removeUnreferencedTracks(transaction, [trackId]);
    });
    if (!result.isEmpty) {
      _emitRevision();
    }

    return result;
  }

  @override
  Future<DownloadRemovalResult> removeAlbum({required int albumId}) async {
    final result = await _database.transaction((transaction) async {
      final rows = await transaction.query(
        'download_references',
        columns: const ['track_id'],
        where: "reason_type = 'album' AND reason_id = ?",
        whereArgs: [albumId],
      );
      final trackIds = rows
          .map((row) => row['track_id']! as int)
          .toList(growable: false);
      await transaction.delete(
        'download_references',
        where: "reason_type = 'album' AND reason_id = ?",
        whereArgs: [albumId],
      );
      final removal = await _removeUnreferencedTracks(transaction, trackIds);

      return removal;
    });
    _emitRevision();

    return result;
  }

  @override
  Future<DownloadRemovalResult> removePlaylist({
    required int playlistId,
  }) async {
    final result = await _database.transaction((transaction) async {
      final rows = await transaction.query(
        'download_references',
        columns: const ['track_id'],
        where: "reason_type = 'playlist' AND reason_id = ?",
        whereArgs: [playlistId],
      );
      final trackIds = rows
          .map((row) => row['track_id']! as int)
          .toList(growable: false);
      await transaction.delete(
        'download_references',
        where: "reason_type = 'playlist' AND reason_id = ?",
        whereArgs: [playlistId],
      );
      await transaction.delete(
        'download_playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      return _removeUnreferencedTracks(transaction, trackIds);
    });
    _emitRevision();

    return result;
  }

  @override
  Future<DownloadRemovalResult> removeAll() async {
    final result = await _database.transaction((transaction) async {
      final trackRows = await transaction.query(
        'download_tracks',
        columns: const ['id'],
        orderBy: 'id',
      );
      final downloadedTrackRows = await transaction.query(
        'download_track_files',
        columns: const ['track_id'],
        orderBy: 'track_id',
      );
      final pathRows = await transaction.rawQuery('''
SELECT audio_relative_path AS relative_path FROM download_track_files
UNION
SELECT temporary_relative_path AS relative_path
FROM download_jobs WHERE temporary_relative_path IS NOT NULL
UNION
SELECT local_relative_path AS relative_path
FROM download_assets WHERE local_relative_path IS NOT NULL
''');
      final paths = pathRows
          .map((row) => row['relative_path']! as String)
          .toSet();
      for (final path in paths) {
        await _enqueuePendingDeletion(transaction, path);
      }

      await transaction.delete('download_jobs');
      await transaction.update('download_batches', {
        'ended_at_ms': _nowMilliseconds,
      }, where: 'ended_at_ms IS NULL');
      await transaction.delete('download_references');
      await transaction.delete('download_track_files');
      await transaction.delete('download_playlists');
      await transaction.delete('download_tracks');
      await transaction.delete('download_albums');
      await transaction.delete('download_authors');
      await transaction.delete('download_assets');

      return DownloadRemovalResult(
        removedTrackIds: trackRows
            .map((row) => row['id']! as int)
            .toList(growable: false),
        removedDownloadedTrackIds: downloadedTrackRows
            .map((row) => row['track_id']! as int)
            .toList(growable: false),
        relativePathsToDelete: paths.toList(growable: false)..sort(),
      );
    });
    _emitRevision();

    return result;
  }

  @override
  Future<void> acknowledgeDeletedPaths(Iterable<String> relativePaths) async {
    final paths = relativePaths.toSet();
    for (final path in paths) {
      _validateRelativePath(path);
    }
    await _database.transaction((transaction) async {
      for (final path in paths) {
        await transaction.delete(
          'pending_file_deletions',
          where: 'relative_path = ?',
          whereArgs: [path],
        );
      }
    });
  }

  @override
  Future<List<String>> getPendingDeletionPaths() async {
    final rows = await _database.query(
      'pending_file_deletions',
      columns: const ['relative_path'],
      orderBy: 'enqueued_at_ms, relative_path',
    );

    return rows
        .map((row) => row['relative_path']! as String)
        .toList(growable: false);
  }

  Future<DownloadRemovalResult> _removeUnreferencedTracks(
    DatabaseExecutor executor,
    Iterable<int> candidateTrackIds,
  ) async {
    final removedTrackIds = <int>[];
    final removedDownloadedTrackIds = <int>[];
    final paths = <String>{};
    final affectedBatchIds = <int>{};
    for (final trackId in candidateTrackIds.toSet()) {
      final hasReference = await _rowExists(
        executor,
        table: 'download_references',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      if (hasReference) {
        continue;
      }
      final fileRows = await executor.query(
        'download_track_files',
        columns: const ['audio_relative_path'],
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      final jobRows = await executor.query(
        'download_jobs',
        columns: const ['batch_id', 'temporary_relative_path'],
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      if (fileRows.isNotEmpty) {
        removedDownloadedTrackIds.add(trackId);
      }
      paths.addAll(
        fileRows.map((row) => row['audio_relative_path']! as String),
      );
      paths.addAll(
        jobRows
            .map((row) => row['temporary_relative_path'] as String?)
            .whereType<String>(),
      );
      affectedBatchIds.addAll(jobRows.map((row) => row['batch_id']! as int));
      await executor.delete(
        'download_jobs',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      await executor.delete(
        'download_track_files',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      final removed = await executor.delete(
        'download_tracks',
        where: 'id = ?',
        whereArgs: [trackId],
      );
      if (removed > 0) {
        removedTrackIds.add(trackId);
      }
    }
    for (final batchId in affectedBatchIds) {
      await _finishBatchIfIdle(executor, batchId);
    }
    await _removeUnusedAlbumsAuthorsAndAssets(executor, paths: paths);
    for (final path in paths) {
      await _enqueuePendingDeletion(executor, path);
    }

    removedTrackIds.sort();
    removedDownloadedTrackIds.sort();
    final sortedPaths = paths.toList()..sort();

    return DownloadRemovalResult(
      removedTrackIds: removedTrackIds,
      removedDownloadedTrackIds: removedDownloadedTrackIds,
      relativePathsToDelete: sortedPaths,
    );
  }

  Future<void> _removeUnusedAlbumsAuthorsAndAssets(
    DatabaseExecutor executor, {
    required Set<String> paths,
  }) async {
    await executor.rawDelete('''
DELETE FROM download_playlists
WHERE NOT EXISTS (
  SELECT 1 FROM download_playlist_tracks
  WHERE download_playlist_tracks.playlist_id = download_playlists.id
)
''');
    await executor.rawDelete('''
DELETE FROM download_albums
WHERE NOT EXISTS (
  SELECT 1 FROM download_tracks WHERE download_tracks.album_id = download_albums.id
)
''');
    await executor.rawDelete('''
DELETE FROM download_authors
WHERE NOT EXISTS (
  SELECT 1 FROM download_track_authors
  WHERE download_track_authors.author_id = download_authors.id
)
AND NOT EXISTS (
  SELECT 1 FROM download_album_authors
  WHERE download_album_authors.author_id = download_authors.id
)
''');
    final unusedAssets = await executor.rawQuery('''
SELECT assets.id, assets.local_relative_path
FROM download_assets AS assets
WHERE NOT EXISTS (
  SELECT 1 FROM download_tracks WHERE image_asset_id = assets.id
)
AND NOT EXISTS (
  SELECT 1 FROM download_albums WHERE cover_asset_id = assets.id
)
AND NOT EXISTS (
  SELECT 1 FROM download_playlists WHERE cover_asset_id = assets.id
)
AND NOT EXISTS (
  SELECT 1 FROM download_author_photos WHERE asset_id = assets.id
)
''');
    for (final asset in unusedAssets) {
      final path = asset['local_relative_path'] as String?;
      if (path != null) {
        paths.add(path);
      }
      await executor.delete(
        'download_assets',
        where: 'id = ?',
        whereArgs: [asset['id']],
      );
    }
  }

  @override
  Stream<Set<int>> watchDownloadedTrackIds() {
    return _watch(_getDownloadedTrackIds);
  }

  Future<Set<int>> _getDownloadedTrackIds() async {
    final rows = await _database.query(
      'download_track_files',
      columns: const ['track_id'],
    );

    return rows.map((row) => row['track_id']! as int).toSet();
  }

  @override
  Stream<DownloadedLibrarySnapshot> watchLibrary() => _watch(getLibrary);

  @override
  Future<DownloadedLibrarySnapshot> getLibrary() async {
    final values = await Future.wait<Object>([
      getDownloadedTracks(),
      getDownloadedAuthors(),
      getDownloadedAlbums(),
      getDownloadedPlaylists(),
    ]);
    final referenceRows = await _database.query(
      'download_references',
      distinct: true,
      columns: const ['reason_type', 'reason_id'],
      where: "reason_type IN ('album', 'playlist')",
    );

    return DownloadedLibrarySnapshot(
      tracks: values.first as List<Track>,
      authors: values[1] as List<Author>,
      albums: values[2] as List<Album>,
      playlists: values[3] as List<Playlist>,
      albumDownloadIds: referenceRows
          .where((row) => row['reason_type'] == 'album')
          .map((row) => row['reason_id']! as int)
          .toSet(),
      playlistDownloadIds: referenceRows
          .where((row) => row['reason_type'] == 'playlist')
          .map((row) => row['reason_id']! as int)
          .toSet(),
    );
  }

  @override
  Future<List<Track>> getDownloadedTracks() async {
    final rows = await _database.rawQuery('''
SELECT track_id
FROM download_track_files
ORDER BY downloaded_at_ms DESC, track_id
''');

    return _loadTracks(
      _database,
      rows.map((row) => row['track_id']! as int),
      requireDownloaded: true,
      useLocalFiles: true,
    );
  }

  @override
  Future<Track?> getDownloadedTrack({required int trackId}) {
    return _loadTrack(
      _database,
      trackId: trackId,
      requireDownloaded: true,
      useLocalFiles: true,
    );
  }

  @override
  Future<List<Author>> getDownloadedAuthors() async {
    final rows = await _database.rawQuery('''
SELECT DISTINCT authors.id
FROM download_authors AS authors
INNER JOIN download_track_authors AS track_authors
  ON track_authors.author_id = authors.id
INNER JOIN download_track_files AS files
  ON files.track_id = track_authors.track_id
ORDER BY authors.current_name COLLATE NOCASE, authors.id
''');
    final authors = <Author>[];
    for (final row in rows) {
      final author = await _loadAuthor(
        _database,
        row['id']! as int,
        useLocalFiles: true,
      );
      if (author != null) {
        authors.add(author);
      }
    }

    return authors;
  }

  @override
  Future<List<Track>> getDownloadedTracksByAuthor({
    required int authorId,
  }) async {
    final rows = await _database.rawQuery(
      '''
SELECT files.track_id
FROM download_track_files AS files
INNER JOIN download_track_authors AS track_authors
  ON track_authors.track_id = files.track_id
WHERE track_authors.author_id = ?
ORDER BY files.downloaded_at_ms DESC, files.track_id
''',
      [authorId],
    );

    return _loadTracks(
      _database,
      rows.map((row) => row['track_id']! as int),
      requireDownloaded: true,
      useLocalFiles: true,
    );
  }

  @override
  Future<List<Album>> getDownloadedAlbums() async {
    final rows = await _database.rawQuery('''
SELECT DISTINCT albums.id, albums.title
FROM download_albums AS albums
INNER JOIN download_tracks AS tracks ON tracks.album_id = albums.id
INNER JOIN download_track_files AS files ON files.track_id = tracks.id
ORDER BY albums.title COLLATE NOCASE, albums.id
''');
    final albums = <Album>[];
    for (final row in rows) {
      final album = await _loadAlbum(
        _database,
        albumId: row['id']! as int,
        downloadedTracksOnly: true,
        useLocalFiles: true,
      );
      if (album != null) {
        albums.add(album);
      }
    }

    return albums;
  }

  @override
  Future<List<Track>> getDownloadedTracksByAlbum({required int albumId}) async {
    final rows = await _database.rawQuery(
      '''
SELECT files.track_id
FROM download_track_files AS files
INNER JOIN download_tracks AS tracks ON tracks.id = files.track_id
LEFT JOIN download_album_tracks AS album_tracks
  ON album_tracks.album_id = tracks.album_id
  AND album_tracks.track_id = tracks.id
WHERE tracks.album_id = ?
ORDER BY album_tracks.position IS NULL, album_tracks.position, files.downloaded_at_ms
''',
      [albumId],
    );

    return _loadTracks(
      _database,
      rows.map((row) => row['track_id']! as int),
      requireDownloaded: true,
      useLocalFiles: true,
    );
  }

  @override
  Future<List<Playlist>> getDownloadedPlaylists() async {
    final rows = await _database.rawQuery('''
SELECT DISTINCT playlists.*,
  assets.remote_uri AS cover_remote_uri,
  assets.local_relative_path AS cover_local_relative_path,
  assets.state AS cover_state
FROM download_playlists AS playlists
LEFT JOIN download_assets AS assets ON assets.id = playlists.cover_asset_id
INNER JOIN download_playlist_tracks AS playlist_tracks
  ON playlist_tracks.playlist_id = playlists.id
INNER JOIN download_track_files AS files
  ON files.track_id = playlist_tracks.track_id
ORDER BY playlists.name COLLATE NOCASE, playlists.id
''');

    return rows
        .map((row) => _playlistFromRow(row, useLocalFiles: true))
        .toList(growable: false);
  }

  @override
  Future<PlaylistDetailsSnapshot?> getDownloadedPlaylistDetails({
    required int playlistId,
  }) async {
    final playlistRows = await _database.rawQuery(
      '''
SELECT playlists.*,
  assets.remote_uri AS cover_remote_uri,
  assets.local_relative_path AS cover_local_relative_path,
  assets.state AS cover_state
FROM download_playlists AS playlists
LEFT JOIN download_assets AS assets ON assets.id = playlists.cover_asset_id
WHERE playlists.id = ?
LIMIT 1
''',
      [playlistId],
    );
    if (playlistRows.isEmpty) {
      return null;
    }
    final trackRows = await _database.rawQuery(
      '''
SELECT playlist_tracks.track_id
FROM download_playlist_tracks AS playlist_tracks
INNER JOIN download_track_files AS files
  ON files.track_id = playlist_tracks.track_id
WHERE playlist_tracks.playlist_id = ?
ORDER BY playlist_tracks.position
''',
      [playlistId],
    );
    final tracks = await _loadTracks(
      _database,
      trackRows.map((row) => row['track_id']! as int),
      requireDownloaded: true,
      useLocalFiles: true,
    );

    return PlaylistDetailsSnapshot(
      playlist: _playlistFromRow(playlistRows.single, useLocalFiles: true),
      tracks: tracks,
    );
  }

  @override
  Future<TrackLyrics?> getCachedLyrics({required int trackId}) async {
    final snapshot = await getLyricsSnapshot(trackId: trackId);

    return snapshot?.availability == DownloadLyricsAvailability.available
        ? snapshot!.lyrics
        : null;
  }

  @override
  Future<DownloadLyricsSnapshot?> getLyricsSnapshot({
    required int trackId,
  }) async {
    final rows = await _database.query(
      'download_track_lyrics',
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    final availability = DownloadLyricsAvailability.values.byName(
      row['availability']! as String,
    );
    if (availability != DownloadLyricsAvailability.available) {
      return DownloadLyricsSnapshot(
        trackId: trackId,
        availability: availability,
        lyrics: null,
      );
    }
    final lineRows = await _database.query(
      'download_lyrics_lines',
      where: 'track_id = ?',
      whereArgs: [trackId],
      orderBy: 'position',
    );
    final lyrics = TrackLyrics(
      trackId: trackId,
      type: TrackLyricsType.values.byName(row['lyrics_type']! as String),
      languageCode: row['language_code'] as String?,
      isVerified: _intToBool(row['is_verified']),
      source: row['source'] as String?,
      plainText: row['plain_text'] as String?,
      lines: lineRows
          .map(
            (line) => SyncedTrackLyricsLine(
              startMs: line['start_ms']! as int,
              endMs: line['end_ms'] as int?,
              text: line['text']! as String,
            ),
          )
          .toList(growable: false),
    );

    return DownloadLyricsSnapshot.available(lyrics);
  }

  @override
  Future<DownloadedTrackLocation?> getDownloadedTrackLocation({
    required int trackId,
  }) async {
    final rows = await _database.rawQuery(
      '''
SELECT files.audio_relative_path,
  assets.local_relative_path AS artwork_relative_path,
  assets.state AS artwork_state
FROM download_track_files AS files
INNER JOIN download_tracks AS tracks ON tracks.id = files.track_id
LEFT JOIN download_assets AS assets ON assets.id = tracks.image_asset_id
WHERE files.track_id = ?
LIMIT 1
''',
      [trackId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;

    return DownloadedTrackLocation(
      trackId: trackId,
      audioRelativePath: row['audio_relative_path']! as String,
      artworkRelativePath: row['artwork_state'] == 'available'
          ? row['artwork_relative_path'] as String?
          : null,
    );
  }

  Future<List<Track>> _loadTracks(
    DatabaseExecutor executor,
    Iterable<int> trackIds, {
    required bool requireDownloaded,
    required bool useLocalFiles,
  }) async {
    final tracks = <Track>[];
    for (final trackId in trackIds) {
      final track = await _loadTrack(
        executor,
        trackId: trackId,
        requireDownloaded: requireDownloaded,
        useLocalFiles: useLocalFiles,
      );
      if (track != null) {
        tracks.add(track);
      }
    }

    return tracks;
  }

  Future<Track?> _loadTrack(
    DatabaseExecutor executor, {
    required int trackId,
    required bool requireDownloaded,
    required bool useLocalFiles,
  }) async {
    final rows = await executor.rawQuery(
      '''
SELECT tracks.*,
  files.audio_relative_path,
  image.remote_uri AS image_remote_uri,
  image.local_relative_path AS image_local_relative_path,
  image.state AS image_state
FROM download_tracks AS tracks
LEFT JOIN download_track_files AS files ON files.track_id = tracks.id
LEFT JOIN download_assets AS image ON image.id = tracks.image_asset_id
WHERE tracks.id = ?
${requireDownloaded ? 'AND files.track_id IS NOT NULL' : ''}
LIMIT 1
''',
      [trackId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    final authorRows = await executor.query(
      'download_track_authors',
      columns: const ['author_id'],
      where: 'track_id = ?',
      whereArgs: [trackId],
      orderBy: 'position',
    );
    final authors = <Author>[];
    for (final authorRow in authorRows) {
      final author = await _loadAuthor(
        executor,
        authorRow['author_id']! as int,
        useLocalFiles: useLocalFiles,
      );
      if (author != null) {
        authors.add(author);
      }
    }
    final info = await _loadAdditionalInfo(
      executor,
      table: 'download_track_additional_info',
      ownerColumn: 'track_id',
      ownerId: trackId,
    );
    final audioRelativePath = row['audio_relative_path'] as String?;
    final audioFile = useLocalFiles && audioRelativePath != null
        ? LocalFile(path: _localPathResolver(audioRelativePath))
        : HttpFile(uri: Uri.parse(row['audio_remote_uri']! as String));
    final imageFile = _fileFromAssetRow(
      remoteUri: row['image_remote_uri'] as String?,
      localRelativePath: row['image_local_relative_path'] as String?,
      state: row['image_state'] as String?,
      useLocalFiles: useLocalFiles,
    );

    return Track(
      id: row['id']! as int,
      albumId: row['album_id'] as int?,
      name: row['name']! as String,
      authors: authors,
      addionalInfo: info,
      file: audioFile,
      image: imageFile,
      isFavorite: _intToBool(row['is_favorite']),
      isDisliked: _intToBool(row['is_disliked']),
      isAvailable: _intToBool(row['is_available']),
      createdAt: _dateTimeFromMilliseconds(row['created_at_ms']),
    );
  }

  Future<Author?> _loadAuthor(
    DatabaseExecutor executor,
    int authorId, {
    required bool useLocalFiles,
  }) async {
    final rows = await executor.query(
      'download_authors',
      where: 'id = ?',
      whereArgs: [authorId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final photoRows = await executor.rawQuery(
      '''
SELECT assets.remote_uri, assets.local_relative_path, assets.state
FROM download_author_photos AS photos
INNER JOIN download_assets AS assets ON assets.id = photos.asset_id
WHERE photos.author_id = ?
ORDER BY photos.position
''',
      [authorId],
    );

    return Author(
      id: authorId,
      currentName: rows.single['current_name']! as String,
      photos: photoRows
          .map((photo) {
            final localPath = photo['local_relative_path'] as String?;
            if (useLocalFiles &&
                photo['state'] == 'available' &&
                localPath != null) {
              return Uri.file(_localPathResolver(localPath)).toString();
            }

            return photo['remote_uri']! as String;
          })
          .toList(growable: false),
    );
  }

  Future<Album?> _loadAlbum(
    DatabaseExecutor executor, {
    required int albumId,
    required bool downloadedTracksOnly,
    required bool useLocalFiles,
  }) async {
    final rows = await executor.rawQuery(
      '''
SELECT albums.*,
  assets.remote_uri AS cover_remote_uri,
  assets.local_relative_path AS cover_local_relative_path,
  assets.state AS cover_state
FROM download_albums AS albums
LEFT JOIN download_assets AS assets ON assets.id = albums.cover_asset_id
WHERE albums.id = ?
LIMIT 1
''',
      [albumId],
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    final authorRows = await executor.query(
      'download_album_authors',
      columns: const ['author_id'],
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'position',
    );
    final List<Map<String, Object?>> trackRows;
    if (downloadedTracksOnly) {
      trackRows = await executor.rawQuery(
        '''
SELECT tracks.id AS track_id
FROM download_tracks AS tracks
INNER JOIN download_track_files AS files ON files.track_id = tracks.id
LEFT JOIN download_album_tracks AS album_tracks
  ON album_tracks.album_id = tracks.album_id
  AND album_tracks.track_id = tracks.id
WHERE tracks.album_id = ?
ORDER BY album_tracks.position IS NULL, album_tracks.position,
  files.downloaded_at_ms, tracks.id
''',
        [albumId],
      );
    } else {
      trackRows = await executor.query(
        'download_album_tracks',
        columns: const ['track_id'],
        where: 'album_id = ?',
        whereArgs: [albumId],
        orderBy: 'position',
      );
    }
    final additionalInfo = await _loadAdditionalInfo(
      executor,
      table: 'download_album_additional_info',
      ownerColumn: 'album_id',
      ownerId: albumId,
    );

    return Album(
      id: albumId,
      title: row['title']! as String,
      coverImage: _fileFromAssetRow(
        remoteUri: row['cover_remote_uri'] as String?,
        localRelativePath: row['cover_local_relative_path'] as String?,
        state: row['cover_state'] as String?,
        useLocalFiles: useLocalFiles,
      ),
      authorIds: authorRows
          .map((author) => author['author_id']! as int)
          .toList(growable: false),
      releaseDate: _dateTimeFromMilliseconds(row['release_date_ms']),
      isPublished: _intToBool(row['is_published']),
      trackIds: trackRows
          .map((track) => track['track_id']! as int)
          .toList(growable: false),
      additionalInfo: additionalInfo,
    );
  }

  Future<List<TrackInfo>> _loadAdditionalInfo(
    DatabaseExecutor executor, {
    required String table,
    required String ownerColumn,
    required int ownerId,
  }) async {
    final rows = await executor.query(
      table,
      where: '$ownerColumn = ?',
      whereArgs: [ownerId],
      orderBy: 'position',
    );

    return rows
        .where((row) => row['kind'] == 'text')
        .map(
          (row) => TextTrackInfo(
            title: row['title']! as String,
            text: row['text']! as String,
          ),
        )
        .toList(growable: false);
  }

  AbstractFile _fileFromAssetRow({
    required String? remoteUri,
    required String? localRelativePath,
    required String? state,
    required bool useLocalFiles,
  }) {
    if (useLocalFiles && state == 'available' && localRelativePath != null) {
      return LocalFile(path: _localPathResolver(localRelativePath));
    }

    return HttpFile(uri: Uri.tryParse(remoteUri ?? '') ?? Uri());
  }

  Playlist _playlistFromRow(
    Map<String, Object?> row, {
    required bool useLocalFiles,
  }) {
    final localRelativePath = row['cover_local_relative_path'] as String?;
    final coverImagePath =
        useLocalFiles &&
            row['cover_state'] == 'available' &&
            localRelativePath != null
        ? Uri.file(_localPathResolver(localRelativePath)).toString()
        : (row['cover_remote_uri'] as String?) ?? '';

    return Playlist(
      id: row['id']! as int,
      userId: row['user_id']! as int,
      name: row['name']! as String,
      description: row['description']! as String,
      coverImagePath: coverImagePath,
      visibility: PlaylistVisibility.values.byName(
        row['visibility']! as String,
      ),
      trackCount: row['track_count']! as int,
      system: _intToBool(row['system']),
      kind: PlaylistKind.values.byName(row['kind']! as String),
      shareToken: row['share_token'] as String?,
    );
  }

  void _validateSnapshot(DownloadTrackSnapshot snapshot) {
    if (snapshot.track.id != snapshot.lyrics.trackId) {
      throw ArgumentError(
        'Track ${snapshot.track.id} has lyrics snapshot for '
        '${snapshot.lyrics.trackId}',
      );
    }
  }

  int get _nowMilliseconds => _clock().toUtc().millisecondsSinceEpoch;

  void _emitRevision() {
    _revision += 1;
    if (!_revisions.isClosed) {
      _revisions.add(_revision);
    }
  }

  static String _identityPathResolver(String path) => path;

  static int _boolToInt(bool value) => value ? 1 : 0;

  static bool _intToBool(Object? value) => value == 1;

  static Uri? _fileUri(AbstractFile file) {
    return switch (file) {
      HttpFile(:final uri) => uri,
      LocalFile(:final path) => Uri.file(path),
      _ => null,
    };
  }

  static Future<bool> _rowExists(
    DatabaseExecutor executor, {
    required String table,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final rows = await executor.query(
      table,
      columns: const ['1'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return rows.isNotEmpty;
  }
}
