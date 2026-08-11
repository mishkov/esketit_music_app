import 'package:sqflite/sqflite.dart';

class DownloadsDatabase {
  static const int schemaVersion = 1;

  static Future<Database> open({
    required String path,
    DatabaseFactory? factory,
  }) {
    final selectedFactory = factory ?? databaseFactory;

    return selectedFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: createSchema,
      ),
    );
  }

  static Future<void> createSchema(Database database, int version) async {
    await database.execute('''
CREATE TABLE download_assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_uri TEXT NOT NULL UNIQUE,
  local_relative_path TEXT UNIQUE,
  kind TEXT NOT NULL CHECK (
    kind IN ('trackArtwork', 'albumArtwork', 'playlistArtwork', 'authorPhoto')
  ),
  state TEXT NOT NULL DEFAULT 'pending' CHECK (
    state IN ('pending', 'available', 'failed', 'absent')
  ),
  byte_count INTEGER,
  mime_type TEXT,
  entity_tag TEXT,
  last_modified TEXT,
  CHECK (byte_count IS NULL OR byte_count >= 0)
)
''');
    await database.execute('''
CREATE TABLE download_authors (
  id INTEGER PRIMARY KEY,
  current_name TEXT NOT NULL
)
''');
    await database.execute('''
CREATE TABLE download_author_photos (
  author_id INTEGER NOT NULL REFERENCES download_authors(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  asset_id INTEGER NOT NULL REFERENCES download_assets(id),
  PRIMARY KEY (author_id, position),
  UNIQUE (author_id, asset_id)
)
''');
    await database.execute('''
CREATE TABLE download_albums (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  cover_asset_id INTEGER REFERENCES download_assets(id),
  release_date_ms INTEGER,
  is_published INTEGER NOT NULL CHECK (is_published IN (0, 1)),
  snapshotted_at_ms INTEGER NOT NULL
)
''');
    await database.execute('''
CREATE TABLE download_album_authors (
  album_id INTEGER NOT NULL REFERENCES download_albums(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  author_id INTEGER NOT NULL REFERENCES download_authors(id),
  PRIMARY KEY (album_id, position),
  UNIQUE (album_id, author_id)
)
''');
    await database.execute(
      'CREATE INDEX download_album_authors_author_id '
      'ON download_album_authors(author_id)',
    );
    await database.execute('''
CREATE TABLE download_album_tracks (
  album_id INTEGER NOT NULL REFERENCES download_albums(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  track_id INTEGER NOT NULL,
  PRIMARY KEY (album_id, position),
  UNIQUE (album_id, track_id)
)
''');
    await database.execute(
      'CREATE INDEX download_album_tracks_track_id '
      'ON download_album_tracks(track_id)',
    );
    await database.execute('''
CREATE TABLE download_album_additional_info (
  album_id INTEGER NOT NULL REFERENCES download_albums(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  kind TEXT NOT NULL CHECK (kind IN ('text')),
  title TEXT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (album_id, position)
)
''');
    await database.execute('''
CREATE TABLE download_tracks (
  id INTEGER PRIMARY KEY,
  album_id INTEGER REFERENCES download_albums(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  audio_remote_uri TEXT NOT NULL,
  image_asset_id INTEGER REFERENCES download_assets(id),
  is_favorite INTEGER NOT NULL CHECK (is_favorite IN (0, 1)),
  is_disliked INTEGER NOT NULL CHECK (is_disliked IN (0, 1)),
  is_available INTEGER NOT NULL CHECK (is_available IN (0, 1)),
  created_at_ms INTEGER,
  snapshotted_at_ms INTEGER NOT NULL
)
''');
    await database.execute(
      'CREATE INDEX download_tracks_album_id ON download_tracks(album_id)',
    );
    await database.execute('''
CREATE TABLE download_track_authors (
  track_id INTEGER NOT NULL REFERENCES download_tracks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  author_id INTEGER NOT NULL REFERENCES download_authors(id),
  PRIMARY KEY (track_id, position),
  UNIQUE (track_id, author_id)
)
''');
    await database.execute(
      'CREATE INDEX download_track_authors_author_id '
      'ON download_track_authors(author_id)',
    );
    await database.execute('''
CREATE TABLE download_track_additional_info (
  track_id INTEGER NOT NULL REFERENCES download_tracks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  kind TEXT NOT NULL CHECK (kind IN ('text')),
  title TEXT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (track_id, position)
)
''');
    await database.execute('''
CREATE TABLE download_playlists (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  cover_asset_id INTEGER REFERENCES download_assets(id),
  visibility TEXT NOT NULL CHECK (
    visibility IN ('private', 'public', 'shared')
  ),
  track_count INTEGER NOT NULL CHECK (track_count >= 0),
  system INTEGER NOT NULL CHECK (system IN (0, 1)),
  kind TEXT NOT NULL CHECK (kind IN ('custom', 'favorites', 'dislikes')),
  share_token TEXT,
  snapshotted_at_ms INTEGER NOT NULL
)
''');
    await database.execute('''
CREATE TABLE download_playlist_tracks (
  playlist_id INTEGER NOT NULL REFERENCES download_playlists(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  track_id INTEGER NOT NULL REFERENCES download_tracks(id) ON DELETE CASCADE,
  PRIMARY KEY (playlist_id, position),
  UNIQUE (playlist_id, track_id)
)
''');
    await database.execute(
      'CREATE INDEX download_playlist_tracks_track_id '
      'ON download_playlist_tracks(track_id)',
    );
    await database.execute('''
CREATE TABLE download_track_lyrics (
  track_id INTEGER PRIMARY KEY REFERENCES download_tracks(id) ON DELETE CASCADE,
  availability TEXT NOT NULL CHECK (
    availability IN ('notFetched', 'available', 'notAvailable')
  ),
  lyrics_type TEXT CHECK (lyrics_type IS NULL OR lyrics_type IN ('plain', 'synced')),
  language_code TEXT,
  is_verified INTEGER CHECK (is_verified IS NULL OR is_verified IN (0, 1)),
  source TEXT,
  plain_text TEXT
)
''');
    await database.execute('''
CREATE TABLE download_lyrics_lines (
  track_id INTEGER NOT NULL REFERENCES download_track_lyrics(track_id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  start_ms INTEGER NOT NULL CHECK (start_ms >= 0),
  end_ms INTEGER,
  text TEXT NOT NULL,
  PRIMARY KEY (track_id, position)
)
''');
    await database.execute('''
CREATE TABLE download_references (
  track_id INTEGER NOT NULL REFERENCES download_tracks(id) ON DELETE CASCADE,
  reason_type TEXT NOT NULL CHECK (
    reason_type IN ('track', 'album', 'playlist')
  ),
  reason_id INTEGER NOT NULL,
  PRIMARY KEY (track_id, reason_type, reason_id),
  CHECK (reason_type != 'track' OR reason_id = track_id)
)
''');
    await database.execute(
      'CREATE INDEX download_references_reason '
      'ON download_references(reason_type, reason_id)',
    );
    await database.execute('''
CREATE TABLE download_track_files (
  track_id INTEGER PRIMARY KEY REFERENCES download_tracks(id) ON DELETE CASCADE,
  audio_relative_path TEXT NOT NULL UNIQUE,
  byte_count INTEGER NOT NULL CHECK (byte_count >= 0),
  downloaded_at_ms INTEGER NOT NULL,
  entity_tag TEXT,
  last_modified TEXT
)
''');
    await database.execute(
      'CREATE INDEX download_track_files_downloaded_at '
      'ON download_track_files(downloaded_at_ms DESC)',
    );
    await database.execute('''
CREATE TABLE download_batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at_ms INTEGER NOT NULL,
  ended_at_ms INTEGER
)
''');
    await database.execute('''
CREATE UNIQUE INDEX download_batches_one_active
ON download_batches((1))
WHERE ended_at_ms IS NULL
''');
    await database.execute('''
CREATE TABLE download_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL REFERENCES download_batches(id) ON DELETE CASCADE,
  track_id INTEGER NOT NULL REFERENCES download_tracks(id) ON DELETE CASCADE,
  state TEXT NOT NULL CHECK (
    state IN ('queued', 'downloading', 'waitingToRetry', 'failed')
  ),
  enqueued_at_ms INTEGER NOT NULL,
  started_at_ms INTEGER,
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at_ms INTEGER,
  received_bytes INTEGER NOT NULL DEFAULT 0 CHECK (received_bytes >= 0),
  total_bytes INTEGER CHECK (total_bytes IS NULL OR total_bytes >= 0),
  temporary_relative_path TEXT,
  entity_tag TEXT,
  last_modified TEXT,
  failure_kind TEXT,
  failure_message TEXT,
  failure_acknowledged_at_ms INTEGER
)
''');
    await database.execute('''
CREATE INDEX download_jobs_state_id ON download_jobs(state, id)
''');
    await database.execute('''
CREATE UNIQUE INDEX download_jobs_one_active_per_track
ON download_jobs(track_id)
WHERE state IN ('queued', 'downloading', 'waitingToRetry')
''');
    await database.execute('''
CREATE TABLE pending_file_deletions (
  relative_path TEXT PRIMARY KEY,
  enqueued_at_ms INTEGER NOT NULL
)
''');
  }
}
