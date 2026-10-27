package com.antigravity.rewind.data.scanner

import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build

data class CodecInfo(
    val mimeType: String,
    val formatName: String,
    val codecName: String,
    val isHardwareAccelerated: Boolean,
    val isSupported: Boolean
)

object HardwareCodecInspector {

    private val targetFormats = listOf(
        MediaFormat.MIMETYPE_AUDIO_MPEG to "MP3",
        MediaFormat.MIMETYPE_AUDIO_AAC to "AAC",
        MediaFormat.MIMETYPE_AUDIO_FLAC to "FLAC (Lossless)",
        MediaFormat.MIMETYPE_AUDIO_OPUS to "OPUS",
        MediaFormat.MIMETYPE_AUDIO_VORBIS to "OGG Vorbis",
        MediaFormat.MIMETYPE_AUDIO_RAW to "PCM / WAV"
    )

    fun inspectAudioCodecs(): List<CodecInfo> {
        val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
        val allCodecInfos = codecList.codecInfos

        return targetFormats.map { (mime, formatLabel) ->
            var matchingCodec: android.media.MediaCodecInfo? = null
            var isHw = false

            for (info in allCodecInfos) {
                if (info.isEncoder) continue
                try {
                    val caps = info.getCapabilitiesForType(mime)
                    if (caps != null) {
                        matchingCodec = info
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            if (info.isHardwareAccelerated) {
                                isHw = true
                                break
                            }
                        } else {
                            val name = info.name.lowercase()
                            if (!name.startsWith("omx.google.") && !name.startsWith("c2.android.")) {
                                isHw = true
                                break
                            }
                        }
                    }
                } catch (_: Exception) {}
            }

            CodecInfo(
                mimeType = mime,
                formatName = formatLabel,
                codecName = matchingCodec?.name ?: "Android Default ExoPlayer Parser",
                isHardwareAccelerated = isHw,
                isSupported = matchingCodec != null
            )
        }
    }
}
