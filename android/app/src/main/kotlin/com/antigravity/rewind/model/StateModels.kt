package com.antigravity.rewind.model

data class PlaybackState(
    val currentTrack: AudioTrack? = null,
    val isPlaying: Boolean = false,
    val positionMs: Long = 0L,
    val durationMs: Long = 0L,
    val queue: List<AudioTrack> = emptyList(),
    val currentIndex: Int = -1,
    val isShuffle: Boolean = false,
    val isRepeatOne: Boolean = false,
    val volume: Float = 1.0f
)

data class AppSettings(
    val customBackgroundImagePath: String? = null,
    val useSongBannerCanvas: Boolean = true,
    val backgroundDimLevel: Float = 0.50f,
    val backgroundBlurSigma: Float = 6.0f,
    val accentColorValue: Long = 0xFF1DF74B, // Rewind Green default (#1DF74B)
    val enableMechanicalSounds: Boolean = true,
    val enableCassetteSounds: Boolean = true,
    val enableMotorAmbience: Boolean = false,
    val enableHaptics: Boolean = true,
    val uiSoundVolume: Float = 0.8f,
    val soundProfile: String = "classic",
    val reducedAnimation: Boolean = false,
    val walkmanMode: Boolean = false,
    val walkmanChassisTheme: String = "classicBlue",
    val walkmanCustomSkinPath: String? = null,
    val walkmanBrandingText: String = "SONY",
    val walkmanHotlineColorValue: Long = 0xFFF08A1C,
    val gaplessPlayback: Boolean = true,
    val excludedFolders: List<String> = listOf("Ringtones", "Notifications", "Alarms", "WhatsApp Audio")
)
