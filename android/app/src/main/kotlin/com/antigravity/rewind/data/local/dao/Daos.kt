package com.antigravity.rewind.data.local.dao

import androidx.room.*
import com.antigravity.rewind.data.local.entity.*
import kotlinx.coroutines.flow.Flow

@Dao
interface SongDao {
    @Query("SELECT * FROM songs ORDER BY title ASC")
    fun getAllSongsFlow(): Flow<List<SongEntity>>

    @Query("SELECT * FROM songs ORDER BY title ASC")
    suspend fun getAllSongs(): List<SongEntity>

    @Query("SELECT * FROM songs WHERE title LIKE '%' || :query || '%' OR artist LIKE '%' || :query || '%' OR album LIKE '%' || :query || '%' ORDER BY title ASC")
    suspend fun searchSongs(query: String): List<SongEntity>

    @Query("SELECT * FROM songs WHERE album = :albumName ORDER BY track_number ASC, title ASC")
    suspend fun getSongsByAlbum(albumName: String): List<SongEntity>

    @Query("SELECT * FROM songs WHERE is_favorite = 1 ORDER BY title ASC")
    fun getFavoriteSongsFlow(): Flow<List<SongEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSongs(songs: List<SongEntity>)

    @Query("UPDATE songs SET is_favorite = :isFavorite WHERE id = :id")
    suspend fun updateFavorite(id: String, isFavorite: Int)

    @Query("UPDATE songs SET play_count = play_count + 1 WHERE id = :id")
    suspend fun incrementPlayCount(id: String)

    @Query("UPDATE songs SET custom_art_path = :artPath WHERE id = :id")
    suspend fun updateCustomArt(id: String, artPath: String?)

    @Query("UPDATE songs SET custom_art_path = :artPath WHERE album = :album")
    suspend fun updateAlbumCustomArt(album: String, artPath: String?)
}

@Dao
interface PlaylistDao {
    @Query("SELECT * FROM playlists ORDER BY created_at DESC")
    fun getAllPlaylistsFlow(): Flow<List<PlaylistEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylist(playlist: PlaylistEntity)

    @Query("DELETE FROM playlists WHERE id = :id")
    suspend fun deletePlaylist(id: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addSongToPlaylist(crossRef: PlaylistSongCrossRef)

    @Query("DELETE FROM playlist_songs WHERE playlist_id = :playlistId AND song_id = :songId")
    suspend fun removeSongFromPlaylist(playlistId: String, songId: String)

    @Query("""
        SELECT s.* FROM songs s
        INNER JOIN playlist_songs ps ON s.id = ps.song_id
        WHERE ps.playlist_id = :playlistId
        ORDER BY ps.sort_order ASC
    """)
    fun getPlaylistSongsFlow(playlistId: String): Flow<List<SongEntity>>

    @Query("SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = :playlistId")
    suspend fun getPlaylistSongCount(playlistId: String): Int
}

@Dao
interface PlaybackHistoryDao {
    @Insert
    suspend fun insertHistory(entry: PlaybackHistoryEntity)

    @Query("DELETE FROM playback_history")
    suspend fun clearHistory()

    @Query("""
        SELECT s.* FROM songs s
        INNER JOIN playback_history h ON s.id = h.song_id
        ORDER BY h.played_at DESC LIMIT 50
    """)
    fun getRecentHistorySongsFlow(): Flow<List<SongEntity>>
}

@Dao
interface SettingDao {
    @Query("SELECT * FROM app_settings")
    suspend fun getAllSettings(): List<SettingEntity>

    @Query("SELECT * FROM app_settings")
    fun getAllSettingsFlow(): Flow<List<SettingEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveSetting(setting: SettingEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun saveSettings(settings: List<SettingEntity>)
}
