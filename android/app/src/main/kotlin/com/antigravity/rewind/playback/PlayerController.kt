package com.antigravity.rewind.playback

import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import com.antigravity.rewind.model.AudioTrack
import com.antigravity.rewind.model.PlaybackState
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class PlayerController(
    private val context: Context,
    private val coroutineScope: CoroutineScope
) {
    private var exoPlayer: ExoPlayer? = null

    private val _playbackState = MutableStateFlow(PlaybackState())
    val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    private var positionJob: Job? = null

    init {
        initPlayer()
    }

    @OptIn(UnstableApi::class)
    private fun initPlayer() {
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
            .setUsage(C.USAGE_MEDIA)
            .build()

        exoPlayer = ExoPlayer.Builder(context)
            .setAudioAttributes(audioAttributes, true)
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_LOCAL)
            .build().apply {
                addListener(object : Player.Listener {
                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        _playbackState.update { it.copy(isPlaying = isPlaying) }
                        if (isPlaying) {
                            startPositionUpdates()
                        } else {
                            stopPositionUpdates()
                        }
                    }

                    override fun onPlaybackStateChanged(state: Int) {
                        when (state) {
                            Player.STATE_READY -> {
                                _playbackState.update {
                                    it.copy(
                                        durationMs = duration.coerceAtLeast(0L),
                                        positionMs = currentPosition.coerceAtLeast(0L)
                                    )
                                }
                            }
                            Player.STATE_ENDED -> {
                                onTrackEnded()
                            }
                            else -> {}
                        }
                    }

                    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                        val player = exoPlayer ?: return
                        val index = player.currentMediaItemIndex
                        val currentQueue = _playbackState.value.queue
                        if (index in currentQueue.indices) {
                            _playbackState.update {
                                it.copy(
                                    currentTrack = currentQueue[index],
                                    currentIndex = index
                                )
                            }
                        }
                    }
                })
            }
    }

    private fun startPositionUpdates() {
        positionJob?.cancel()
        positionJob = coroutineScope.launch {
            while (isActive) {
                exoPlayer?.let { player ->
                    if (player.isPlaying) {
                        _playbackState.update {
                            it.copy(
                                positionMs = player.currentPosition.coerceAtLeast(0L),
                                durationMs = player.duration.coerceAtLeast(0L)
                            )
                        }
                    }
                }
                delay(200L)
            }
        }
    }

    private fun stopPositionUpdates() {
        positionJob?.cancel()
        positionJob = null
    }

    fun playTrack(track: AudioTrack, queue: List<AudioTrack> = listOf(track)) {
        val player = exoPlayer ?: return
        val targetIndex = queue.indexOfFirst { it.id == track.id }.coerceAtLeast(0)

        _playbackState.update {
            it.copy(
                queue = queue,
                currentIndex = targetIndex,
                currentTrack = track,
                positionMs = 0L,
                durationMs = track.durationMs
            )
        }

        player.clearMediaItems()
        val mediaItems = queue.map { item ->
            val metadata = MediaMetadata.Builder()
                .setTitle(item.title)
                .setArtist(item.artist)
                .setAlbumTitle(item.album)
                .setArtworkUri(if (item.customArtPath != null) Uri.parse(item.customArtPath) else null)
                .build()

            MediaItem.Builder()
                .setMediaId(item.id)
                .setUri(item.uri)
                .setMediaMetadata(metadata)
                .build()
        }

        player.setMediaItems(mediaItems, targetIndex, 0L)
        player.prepare()
        player.play()
    }

    fun togglePlayPause() {
        val player = exoPlayer ?: return
        if (player.isPlaying) {
            player.pause()
        } else {
            if (player.playbackState == Player.STATE_IDLE && _playbackState.value.currentTrack != null) {
                playTrack(_playbackState.value.currentTrack!!, _playbackState.value.queue)
            } else {
                player.play()
            }
        }
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun resume() {
        exoPlayer?.play()
    }

    fun seekTo(positionMs: Long) {
        val player = exoPlayer ?: return
        player.seekTo(positionMs.coerceAtLeast(0L))
        _playbackState.update { it.copy(positionMs = positionMs) }
    }

    fun skipToNext() {
        val state = _playbackState.value
        if (state.queue.isEmpty()) return
        val nextIndex = (state.currentIndex + 1) % state.queue.size
        playTrack(state.queue[nextIndex], state.queue)
    }

    fun skipToPrevious() {
        val state = _playbackState.value
        if (state.queue.isEmpty()) return
        val player = exoPlayer
        if (player != null && player.currentPosition > 3000L) {
            seekTo(0L)
            return
        }
        val prevIndex = if (state.currentIndex > 0) state.currentIndex - 1 else state.queue.size - 1
        playTrack(state.queue[prevIndex], state.queue)
    }

    fun toggleShuffle() {
        val nextShuffle = !_playbackState.value.isShuffle
        _playbackState.update { it.copy(isShuffle = nextShuffle) }
        exoPlayer?.shuffleModeEnabled = nextShuffle
    }

    fun toggleRepeat() {
        val nextRepeat = !_playbackState.value.isRepeatOne
        _playbackState.update { it.copy(isRepeatOne = nextRepeat) }
        exoPlayer?.repeatMode = if (nextRepeat) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
    }

    private fun onTrackEnded() {
        val state = _playbackState.value
        if (state.isRepeatOne) {
            seekTo(0L)
            resume()
        } else if (state.currentIndex < state.queue.size - 1) {
            skipToNext()
        } else {
            pause()
            seekTo(0L)
        }
    }

    fun release() {
        stopPositionUpdates()
        exoPlayer?.release()
        exoPlayer = null
    }
}
