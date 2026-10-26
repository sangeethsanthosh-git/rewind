import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/audio_player/domain/audio_track.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static Completer<Database>? _dbOpenCompleter;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    if (_dbOpenCompleter != null) return _dbOpenCompleter!.future;

    final completer = Completer<Database>();
    _dbOpenCompleter = completer;
    try {
      _database = await _initDB('spool_music.db');
      completer.complete(_database);
      return _database!;
    } catch (e) {
      completer.completeError(e);
      _dbOpenCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE songs ADD COLUMN custom_art_path TEXT;');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE songs ADD COLUMN lyrics TEXT;');
      } catch (_) {}
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        album_id INTEGER,
        duration_ms INTEGER NOT NULL,
        uri TEXT NOT NULL,
        path TEXT NOT NULL,
        file_extension TEXT NOT NULL,
        bitrate INTEGER,
        sample_rate INTEGER,
        bit_depth INTEGER,
        is_lossless INTEGER NOT NULL DEFAULT 0,
        track_number INTEGER,
        date_added INTEGER,
        genre TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        play_count INTEGER NOT NULL DEFAULT 0,
        custom_art_path TEXT,
        lyrics TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        color_accent INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE playback_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id TEXT NOT NULL,
        played_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album)');
    await db.execute('CREATE INDEX idx_history_played_at ON playback_history(played_at DESC)');
  }

  // --- Song Operations ---
  Future<void> upsertSongs(List<AudioTrack> tracks) async {
    final db = await database;
    final existing = await db.query('songs', columns: ['id', 'is_favorite', 'play_count', 'custom_art_path', 'lyrics']);
    final existingMap = {for (var row in existing) row['id'] as String: row};

    final batch = db.batch();
    for (final track in tracks) {
      final old = existingMap[track.id];
      final trackToInsert = old != null
          ? track.copyWith(
              isFavorite: (old['is_favorite'] as int? ?? 0) == 1,
              playCount: old['play_count'] as int? ?? track.playCount,
              customArtPath: old['custom_art_path'] as String? ?? track.customArtPath,
              lyrics: track.lyrics ?? old['lyrics'] as String?,
            )
          : track;
      batch.insert(
        'songs',
        trackToInsert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AudioTrack>> getAllSongs({String orderBy = 'title ASC'}) async {
    final db = await database;
    final result = await db.query('songs', orderBy: orderBy);
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  Future<List<AudioTrack>> searchSongs(String query) async {
    final db = await database;
    final sanitized = '%$query%';
    final result = await db.query(
      'songs',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: [sanitized, sanitized, sanitized],
      orderBy: 'title ASC',
    );
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  Future<void> toggleFavorite(String songId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'songs',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<void> updateSongCustomArt(String songId, String? customArtPath) async {
    final db = await database;
    await db.update(
      'songs',
      {'custom_art_path': customArtPath},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  Future<void> updateAlbumCustomArt(String album, String? customArtPath) async {
    final db = await database;
    await db.update(
      'songs',
      {'custom_art_path': customArtPath},
      where: 'album = ?',
      whereArgs: [album],
    );
  }

  Future<List<AudioTrack>> getFavoriteSongs() async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  Future<void> recordPlay(String songId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE songs SET play_count = play_count + 1 WHERE id = ?',
      [songId],
    );
    await db.insert('playback_history', {
      'song_id': songId,
      'played_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<AudioTrack>> getRecentlyPlayed({int limit = 30}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT s.* FROM songs s
      INNER JOIN playback_history h ON s.id = h.song_id
      ORDER BY h.played_at DESC
      LIMIT ?
    ''', [limit]);
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  Future<List<AudioTrack>> getMostPlayed({int limit = 30}) async {
    final db = await database;
    final result = await db.query(
      'songs',
      where: 'play_count > 0',
      orderBy: 'play_count DESC',
      limit: limit,
    );
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  // --- Playlist Operations ---
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as track_count
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.created_at DESC
    ''');
  }

  Future<void> createPlaylist(String id, String name, int colorAccent, [String? description]) async {
    final db = await database;
    await db.insert('playlists', {
      'id': id,
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'color_accent': colorAccent,
      'description': description,
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await database;
    await db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'sort_order': count,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<AudioTrack>> getPlaylistSongs(String playlistId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.sort_order ASC
    ''', [playlistId]);
    return result.map((e) => AudioTrack.fromMap(e)).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('playback_history');
    await db.update('songs', {'play_count': 0});
  }

  // --- Settings Persistence ---
  Future<void> saveAllSettings(Map<String, String> settings) async {
    final db = await database;
    await _ensureSettingsTable(db);
    final batch = db.batch();
    for (final entry in settings.entries) {
      batch.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await _ensureSettingsTable(db);
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    await _ensureSettingsTable(db);
    final maps = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    await _ensureSettingsTable(db);
    final maps = await db.query('app_settings');
    final result = <String, String>{};
    for (final row in maps) {
      result[row['key'] as String] = row['value'] as String;
    }
    return result;
  }

  Future<void> _ensureSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
