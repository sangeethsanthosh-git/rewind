package com.antigravity.rewind.playback

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.antigravity.rewind.model.AppSettings

enum class MechanicalSoundType {
    PLAY_CLACK,
    PAUSE_CLICK,
    SKIP_CLICK,
    CASSETTE_INSERT,
    CASSETTE_EJECT,
    DOOR_LATCH
}

class MechanicalAudioEngine(private val context: Context) {
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()
    private var motorStreamId: Int = 0
    private var lastPlayTimeMs: Long = 0L

    private val vibrator: Vibrator by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    init {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(8)
            .setAudioAttributes(audioAttributes)
            .build()

        loadSounds()
    }

    private fun loadSounds() {
        val soundFiles = mapOf(
            "play_clack" to "sounds/btn_play_clack.wav",
            "pause_click" to "sounds/btn_pause_click.wav",
            "skip_click" to "sounds/btn_skip_click.wav",
            "cassette_insert" to "sounds/cassette_insert.wav",
            "cassette_eject" to "sounds/cassette_eject.wav",
            "door_latch" to "sounds/door_latch.wav",
            "motor_hum" to "sounds/motor_hum.wav"
        )

        soundPool?.let { pool ->
            for ((key, path) in soundFiles) {
                try {
                    val afd = context.assets.openFd(path)
                    val soundId = pool.load(afd, 1)
                    soundMap[key] = soundId
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    fun playMechanicalSound(type: MechanicalSoundType, settings: AppSettings) {
        if (!settings.enableMechanicalSounds && !settings.enableHaptics) return

        triggerHaptic(type, settings)

        if (!settings.enableMechanicalSounds) return

        val now = System.currentTimeMillis()
        if (type == MechanicalSoundType.SKIP_CLICK && now - lastPlayTimeMs < 40) return
        lastPlayTimeMs = now

        val key = when (type) {
            MechanicalSoundType.PLAY_CLACK -> "play_clack"
            MechanicalSoundType.PAUSE_CLICK -> "pause_click"
            MechanicalSoundType.SKIP_CLICK -> "skip_click"
            MechanicalSoundType.CASSETTE_INSERT -> "cassette_insert"
            MechanicalSoundType.CASSETTE_EJECT -> "cassette_eject"
            MechanicalSoundType.DOOR_LATCH -> "door_latch"
        }

        val soundId = soundMap[key] ?: return
        val vol = settings.uiSoundVolume.coerceIn(0.0f, 1.0f)
        soundPool?.play(soundId, vol, vol, 1, 0, 1.0f)
    }

    fun updateMotorAmbience(isPlayingMusic: Boolean, settings: AppSettings) {
        if (settings.enableMotorAmbience && isPlayingMusic) {
            if (motorStreamId == 0) {
                val soundId = soundMap["motor_hum"] ?: return
                val vol = (settings.uiSoundVolume * 0.35f).coerceIn(0.0f, 1.0f)
                motorStreamId = soundPool?.play(soundId, vol, vol, 1, -1, 1.0f) ?: 0
            }
        } else {
            if (motorStreamId != 0) {
                soundPool?.stop(motorStreamId)
                motorStreamId = 0
            }
        }
    }

    private fun triggerHaptic(type: MechanicalSoundType, settings: AppSettings) {
        if (!settings.enableHaptics) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val effect = when (type) {
                    MechanicalSoundType.PLAY_CLACK, MechanicalSoundType.PAUSE_CLICK ->
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
                    MechanicalSoundType.SKIP_CLICK, MechanicalSoundType.DOOR_LATCH ->
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                    MechanicalSoundType.CASSETTE_INSERT, MechanicalSoundType.CASSETTE_EJECT ->
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
                }
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(20L)
            }
        } catch (_: Exception) {}
    }

    fun release() {
        soundPool?.release()
        soundPool = null
    }
}
