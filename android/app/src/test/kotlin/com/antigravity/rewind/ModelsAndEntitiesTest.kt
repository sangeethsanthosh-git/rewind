package com.antigravity.rewind

import com.antigravity.rewind.data.local.entity.SongEntity
import com.antigravity.rewind.model.AppSettings
import com.antigravity.rewind.model.AudioTrack
import org.junit.Assert.*
import org.junit.Test

class ModelsAndEntitiesTest {

    @Test
    fun audioTrack_roundTripEntity_preservesAllFields() {
        val original = AudioTrack(
            id = "101",
            title = "Midnight City",
            artist = "M83",
            album = "Hurry Up, We're Dreaming",
            albumId = 55L,
            durationMs = 243000L,
            uri = "content://media/external/audio/media/101",
            path = "/storage/emulated/0/Music/midnight.flac",
            fileExtension = "flac",
            bitrate = 1411,
            sampleRate = 44100,
            bitDepth = 16,
            isLossless = true,
            trackNumber = 2,
            dateAdded = 1680000000L,
            genre = "Electronic",
            isFavorite = true,
            playCount = 14,
            customArtPath = "/storage/art.png",
            lyrics = "Waiting in a car"
        )

        val entity = SongEntity.fromAudioTrack(original)
        val converted = entity.toAudioTrack()

        assertEquals(original.id, converted.id)
        assertEquals(original.title, converted.title)
        assertEquals(original.artist, converted.artist)
        assertEquals(original.album, converted.album)
        assertEquals(original.durationMs, converted.durationMs)
        assertEquals(original.isLossless, converted.isLossless)
        assertEquals(original.isFavorite, converted.isFavorite)
        assertEquals(original.playCount, converted.playCount)
        assertEquals(original.customArtPath, converted.customArtPath)
        assertEquals(original.lyrics, converted.lyrics)
    }

    @Test
    fun appSettings_defaults_areCorrect() {
        val settings = AppSettings()
        assertTrue(settings.enableMechanicalSounds)
        assertTrue(settings.enableCassetteSounds)
        assertFalse(settings.enableMotorAmbience)
        assertTrue(settings.enableHaptics)
        assertEquals("classicBlue", settings.walkmanChassisTheme)
        assertEquals("SONY", settings.walkmanBrandingText)
    }
}
