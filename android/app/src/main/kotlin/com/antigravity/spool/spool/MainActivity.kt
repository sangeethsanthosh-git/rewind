package com.antigravity.spool.spool

import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.SoundPool
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.antigravity.rewind/sound_effects"
    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()
    private var motorStreamId: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(8)
            .setAudioAttributes(audioAttributes)
            .build()

        val soundFiles = mapOf(
            "play_clack" to "assets/sounds/btn_play_clack.wav",
            "pause_click" to "assets/sounds/btn_pause_click.wav",
            "skip_click" to "assets/sounds/btn_skip_click.wav",
            "cassette_insert" to "assets/sounds/cassette_insert.wav",
            "cassette_eject" to "assets/sounds/cassette_eject.wav",
            "door_latch" to "assets/sounds/door_latch.wav",
            "motor_hum" to "assets/sounds/motor_hum.wav"
        )

        val loader = io.flutter.FlutterInjector.instance().flutterLoader()
        for ((key, path) in soundFiles) {
            var loaded = false
            try {
                val assetKey = loader.getLookupKeyForAsset(path)
                val afd: AssetFileDescriptor = context.assets.openFd(assetKey)
                val soundId = soundPool?.load(afd, 1) ?: 0
                soundMap[key] = soundId
                loaded = true
            } catch (e: Exception) {
                // fallback below
            }
            if (!loaded) {
                try {
                    val afd = context.assets.openFd("flutter_assets/$path")
                    val soundId = soundPool?.load(afd, 1) ?: 0
                    soundMap[key] = soundId
                    loaded = true
                } catch (e2: Exception) {
                    // fallback below
                }
            }
            if (!loaded) {
                try {
                    val afd = context.assets.openFd(path)
                    val soundId = soundPool?.load(afd, 1) ?: 0
                    soundMap[key] = soundId
                } catch (e3: Exception) {
                    Log.w("MainActivity", "Failed to load sound $key: ${e3.message}")
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playSound" -> {
                    val name = call.argument<String>("name") ?: ""
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    val soundId = soundMap[name]
                    if (soundId != null && soundId > 0) {
                        soundPool?.play(soundId, volume, volume, 1, 0, 1.0f)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "startMotorHum" -> {
                    val volume = (call.argument<Double>("volume") ?: 0.3).toFloat()
                    val soundId = soundMap["motor_hum"]
                    if (soundId != null && soundId > 0) {
                        if (motorStreamId != 0) {
                            soundPool?.stop(motorStreamId)
                        }
                        motorStreamId = soundPool?.play(soundId, volume, volume, 1, -1, 1.0f) ?: 0
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopMotorHum" -> {
                    if (motorStreamId != 0) {
                        soundPool?.stop(motorStreamId)
                        motorStreamId = 0
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
