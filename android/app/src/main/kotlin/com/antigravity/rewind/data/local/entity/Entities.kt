package com.antigravity.rewind.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.antigravity.rewind.model.AudioTrack

@Entity(
    tableName = "songs",
    indices = [
        Index(value = ["artist"]),
        Index(value = ["album"])
    ]
)
data class SongEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val artist: String,
    val album: String,
    @ColumnInfo(name = "album_id")
    val albumId: Long?,
    @ColumnInfo(name = "duration_ms")
    val durationMs: Long,
    val uri: String,
    val path: String,
    @ColumnInfo(name = "file_extension")
    val fileExtension: String,
    val bitrate: Int?,
    @ColumnInfo(name = "sample_rate")
    val sampleRate: Int?,
    @ColumnInfo(name = "bit_depth")
    val bitDepth: Int?,
    @ColumnInfo(name = "is_lossless", defaultValue = "0")
    val isLossless: Int = 0,
    @ColumnInfo(name = "track_number")
    val trackNumber: Int?,
    @ColumnInfo(name = "date_added")
    val dateAdded: Long?,
    val genre: String?,
    @ColumnInfo(name = "is_favorite", defaultValue = "0")
    val isFavorite: Int = 0,
    @ColumnInfo(name = "play_count", defaultValue = "0")
    val playCount: Int = 0,
    @ColumnInfo(name = "custom_art_path")
    val customArtPath: String?,
    val lyrics: String?
) {
    fun toAudioTrack(): AudioTrack = AudioTrack(
        id = id,
        title = title,
        artist = artist,
        album = album,
        albumId = albumId,
        durationMs = durationMs,
        uri = uri,
        path = path,
        fileExtension = fileExtension,
        bitrate = bitrate,
        sampleRate = sampleRate,
        bitDepth = bitDepth,
        isLossless = isLossless == 1,
        trackNumber = trackNumber,
        dateAdded = dateAdded,
        genre = genre,
        isFavorite = isFavorite == 1,
        playCount = playCount,
        customArtPath = customArtPath,
        lyrics = lyrics
    )

    companion object {
        fun fromAudioTrack(track: AudioTrack): SongEntity = SongEntity(
            id = track.id,
            title = track.title,
            artist = track.artist,
            album = track.album,
            albumId = track.albumId,
            durationMs = track.durationMs,
            uri = track.uri,
            path = track.path,
            fileExtension = track.fileExtension,
            bitrate = track.bitrate,
            sampleRate = track.sampleRate,
            bitDepth = track.bitDepth,
            isLossless = if (track.isLossless) 1 else 0,
            trackNumber = track.trackNumber,
            dateAdded = track.dateAdded,
            genre = track.genre,
            isFavorite = if (track.isFavorite) 1 else 0,
            playCount = track.playCount,
            customArtPath = track.customArtPath,
            lyrics = track.lyrics
        )
    }
}

@Entity(tableName = "playlists")
data class PlaylistEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    @ColumnInfo(name = "created_at")
    val createdAt: Long,
    @ColumnInfo(name = "color_accent")
    val colorAccent: Long,
    val description: String?
)

@Entity(
    tableName = "playlist_songs",
    primaryKeys = ["playlist_id", "song_id"],
    foreignKeys = [
        ForeignKey(
            entity = PlaylistEntity::class,
            parentColumns = ["id"],
            childColumns = ["playlist_id"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = SongEntity::class,
            parentColumns = ["id"],
            childColumns = ["song_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["song_id"])]
)
data class PlaylistSongCrossRef(
    @ColumnInfo(name = "playlist_id")
    val playlistId: String,
    @ColumnInfo(name = "song_id")
    val songId: String,
    @ColumnInfo(name = "sort_order")
    val sortOrder: Int
)

@Entity(
    tableName = "playback_history",
    foreignKeys = [
        ForeignKey(
            entity = SongEntity::class,
            parentColumns = ["id"],
            childColumns = ["song_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["played_at"]), Index(value = ["song_id"])]
)
data class PlaybackHistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    @ColumnInfo(name = "song_id")
    val songId: String,
    @ColumnInfo(name = "played_at")
    val playedAt: Long
)

@Entity(tableName = "app_settings")
data class SettingEntity(
    @PrimaryKey
    val key: String,
    val value: String
)
