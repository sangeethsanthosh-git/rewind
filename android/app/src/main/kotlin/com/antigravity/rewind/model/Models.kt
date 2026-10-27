package com.antigravity.rewind.model

data class AudioTrack(
    val id: String,
    val title: String,
    val artist: String,
    val album: String,
    val albumId: Long? = null,
    val durationMs: Long = 0L,
    val uri: String,
    val path: String,
    val fileExtension: String = "mp3",
    val bitrate: Int? = null,
    val sampleRate: Int? = null,
    val bitDepth: Int? = null,
    val isLossless: Boolean = false,
    val trackNumber: Int? = null,
    val dateAdded: Long? = null,
    val genre: String? = null,
    val isFavorite: Boolean = false,
    val playCount: Int = 0,
    val customArtPath: String? = null,
    val lyrics: String? = null
)

data class Album(
    val id: Long,
    val title: String,
    val artist: String,
    val songCount: Int,
    val customArtPath: String? = null
)

data class Artist(
    val name: String,
    val songCount: Int,
    val albumCount: Int
)

data class Folder(
    val name: String,
    val path: String,
    val songCount: Int
)

data class Playlist(
    val id: String,
    val name: String,
    val createdAt: Long,
    val colorAccent: Long,
    val description: String? = null,
    val songCount: Int = 0
)
