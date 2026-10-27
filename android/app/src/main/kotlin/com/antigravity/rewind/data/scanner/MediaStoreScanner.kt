package com.antigravity.rewind.data.scanner

import android.content.ContentUris
import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import com.antigravity.rewind.model.AudioTrack
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class MediaStoreScanner(private val context: Context) {

    suspend fun scanLocalMedia(
        excludedFolders: List<String> = emptyList(),
        minDurationMs: Long = 15000L
    ): List<AudioTrack> = withContext(Dispatchers.IO) {
        val tracks = mutableListOf<AudioTrack>()

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.DATE_ADDED
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} >= ?"
        val selectionArgs = arrayOf(minDurationMs.toString())
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        try {
            val cursor = context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val titleCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val albumIdCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
                val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val dataCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val trackCol = it.getColumnIndex(MediaStore.Audio.Media.TRACK)
                val dateAddedCol = it.getColumnIndex(MediaStore.Audio.Media.DATE_ADDED)

                while (it.moveToNext()) {
                    val id = it.getLong(idCol).toString()
                    val title = it.getString(titleCol) ?: "Unknown Title"
                    val artist = it.getString(artistCol) ?: "Unknown Artist"
                    val album = it.getString(albumCol) ?: "Unknown Album"
                    val albumId = if (!it.isNull(albumIdCol)) it.getLong(albumIdCol) else null
                    val duration = it.getLong(durationCol)
                    val path = it.getString(dataCol) ?: ""
                    val trackNum = if (trackCol >= 0 && !it.isNull(trackCol)) it.getInt(trackCol) else null
                    val dateAdded = if (dateAddedCol >= 0 && !it.isNull(dateAddedCol)) it.getLong(dateAddedCol) else null

                    // Excluded folders filter
                    val isExcluded = excludedFolders.any { excluded ->
                        path.contains(excluded, ignoreCase = true)
                    }
                    if (isExcluded) continue

                    val fileExt = path.substringAfterLast('.', "mp3").lowercase()
                    val isLossless = fileExt in listOf("flac", "wav", "alac", "aiff", "dsd", "ape")

                    val contentUri = ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        it.getLong(idCol)
                    ).toString()

                    val lyrics: String? = null

                    tracks.add(
                        AudioTrack(
                            id = id,
                            title = title,
                            artist = if (artist == "<unknown>") "Unknown Artist" else artist,
                            album = if (album == "<unknown>") "Unknown Album" else album,
                            albumId = albumId,
                            durationMs = duration,
                            uri = contentUri,
                            path = path,
                            fileExtension = fileExt,
                            isLossless = isLossless,
                            trackNumber = trackNum,
                            dateAdded = dateAdded,
                            lyrics = lyrics
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        tracks
    }
}
