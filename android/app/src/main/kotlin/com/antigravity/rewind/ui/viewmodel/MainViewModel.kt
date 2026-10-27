package com.antigravity.rewind.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.antigravity.rewind.data.local.AppDatabase
import com.antigravity.rewind.data.local.entity.PlaylistEntity
import com.antigravity.rewind.data.local.entity.PlaylistSongCrossRef
import com.antigravity.rewind.data.local.entity.SettingEntity
import com.antigravity.rewind.data.local.entity.SongEntity
import com.antigravity.rewind.data.scanner.MediaStoreScanner
import com.antigravity.rewind.model.*
import com.antigravity.rewind.playback.MechanicalAudioEngine
import com.antigravity.rewind.playback.MechanicalSoundType
import com.antigravity.rewind.playback.PlayerController
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.io.File
import java.util.UUID

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val database = AppDatabase.getInstance(application)
    private val scanner = MediaStoreScanner(application)
    val audioEngine = MechanicalAudioEngine(application)
    val playerController = PlayerController(application, viewModelScope)

    val playbackState: StateFlow<PlaybackState> = playerController.playbackState

    private val _appSettings = MutableStateFlow(AppSettings())
    val appSettings: StateFlow<AppSettings> = _appSettings.asStateFlow()

    val songs: StateFlow<List<AudioTrack>> = database.songDao().getAllSongsFlow()
        .map { entities -> entities.map { it.toAudioTrack() } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val albums: StateFlow<List<Album>> = songs.map { songList ->
        songList.groupBy { it.album }.map { (albumName, trackGroup) ->
            Album(
                id = trackGroup.firstOrNull()?.albumId ?: 0L,
                title = albumName,
                artist = trackGroup.firstOrNull()?.artist ?: "Unknown Artist",
                songCount = trackGroup.size,
                customArtPath = trackGroup.firstOrNull { it.customArtPath != null }?.customArtPath
            )
        }.sortedBy { it.title }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val artists: StateFlow<List<Artist>> = songs.map { songList ->
        songList.groupBy { it.artist }.map { (artistName, trackGroup) ->
            Artist(
                name = artistName,
                songCount = trackGroup.size,
                albumCount = trackGroup.map { it.album }.distinct().size
            )
        }.sortedBy { it.name }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val folders: StateFlow<List<Folder>> = songs.map { songList ->
        songList.groupBy { File(it.path).parent ?: "/storage" }.map { (folderPath, trackGroup) ->
            Folder(
                name = File(folderPath).name.ifEmpty { "Root" },
                path = folderPath,
                songCount = trackGroup.size
            )
        }.sortedBy { it.name }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val playlists: StateFlow<List<Playlist>> = database.playlistDao().getAllPlaylistsFlow()
        .map { entities ->
            entities.map { entity ->
                Playlist(
                    id = entity.id,
                    name = entity.name,
                    createdAt = entity.createdAt,
                    colorAccent = entity.colorAccent,
                    description = entity.description
                )
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val searchQuery = MutableStateFlow("")
    val searchResults: StateFlow<List<AudioTrack>> = combine(searchQuery, songs) { query, allSongs ->
        if (query.isBlank()) {
            emptyList()
        } else {
            allSongs.filter {
                it.title.contains(query, ignoreCase = true) ||
                it.artist.contains(query, ignoreCase = true) ||
                it.album.contains(query, ignoreCase = true)
            }
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        loadSettings()
        scanMedia()
    }

    fun scanMedia() {
        viewModelScope.launch(Dispatchers.IO) {
            val scanned = scanner.scanLocalMedia(excludedFolders = _appSettings.value.excludedFolders)
            if (scanned.isNotEmpty()) {
                val entities = scanned.map { SongEntity.fromAudioTrack(it) }
                database.songDao().insertSongs(entities)
            }
        }
    }

    private fun loadSettings() {
        viewModelScope.launch(Dispatchers.IO) {
            val savedList = database.settingDao().getAllSettings()
            if (savedList.isNotEmpty()) {
                val map = savedList.associate { it.key to it.value }
                val current = _appSettings.value
                _appSettings.value = current.copy(
                    customBackgroundImagePath = map["customBackgroundImagePath"]?.takeIf { it.isNotEmpty() },
                    useSongBannerCanvas = map["useSongBannerCanvas"]?.let { it == "1" } ?: current.useSongBannerCanvas,
                    backgroundDimLevel = map["backgroundDimLevel"]?.toFloatOrNull() ?: current.backgroundDimLevel,
                    backgroundBlurSigma = map["backgroundBlurSigma"]?.toFloatOrNull() ?: current.backgroundBlurSigma,
                    accentColorValue = map["accentColorValue"]?.toLongOrNull() ?: current.accentColorValue,
                    enableMechanicalSounds = map["enableMechanicalSounds"]?.let { it == "1" } ?: current.enableMechanicalSounds,
                    enableCassetteSounds = map["enableCassetteSounds"]?.let { it == "1" } ?: current.enableCassetteSounds,
                    enableMotorAmbience = map["enableMotorAmbience"]?.let { it == "1" } ?: current.enableMotorAmbience,
                    enableHaptics = map["enableHaptics"]?.let { it == "1" } ?: current.enableHaptics,
                    uiSoundVolume = map["uiSoundVolume"]?.toFloatOrNull() ?: current.uiSoundVolume,
                    walkmanChassisTheme = map["walkmanChassisTheme"] ?: current.walkmanChassisTheme,
                    walkmanCustomSkinPath = map["walkmanCustomSkinPath"]?.takeIf { it.isNotEmpty() },
                    walkmanBrandingText = map["walkmanBrandingText"] ?: current.walkmanBrandingText,
                    gaplessPlayback = map["gaplessPlayback"]?.let { it == "1" } ?: current.gaplessPlayback
                )
            }
        }
    }

    fun updateSettings(newSettings: AppSettings) {
        _appSettings.value = newSettings
        viewModelScope.launch(Dispatchers.IO) {
            val entities = listOf(
                SettingEntity("customBackgroundImagePath", newSettings.customBackgroundImagePath ?: ""),
                SettingEntity("useSongBannerCanvas", if (newSettings.useSongBannerCanvas) "1" else "0"),
                SettingEntity("backgroundDimLevel", newSettings.backgroundDimLevel.toString()),
                SettingEntity("backgroundBlurSigma", newSettings.backgroundBlurSigma.toString()),
                SettingEntity("accentColorValue", newSettings.accentColorValue.toString()),
                SettingEntity("enableMechanicalSounds", if (newSettings.enableMechanicalSounds) "1" else "0"),
                SettingEntity("enableCassetteSounds", if (newSettings.enableCassetteSounds) "1" else "0"),
                SettingEntity("enableMotorAmbience", if (newSettings.enableMotorAmbience) "1" else "0"),
                SettingEntity("enableHaptics", if (newSettings.enableHaptics) "1" else "0"),
                SettingEntity("uiSoundVolume", newSettings.uiSoundVolume.toString()),
                SettingEntity("walkmanChassisTheme", newSettings.walkmanChassisTheme),
                SettingEntity("walkmanCustomSkinPath", newSettings.walkmanCustomSkinPath ?: ""),
                SettingEntity("walkmanBrandingText", newSettings.walkmanBrandingText),
                SettingEntity("gaplessPlayback", if (newSettings.gaplessPlayback) "1" else "0")
            )
            database.settingDao().saveSettings(entities)
        }
    }

    fun playTrack(track: AudioTrack, queue: List<AudioTrack> = songs.value) {
        audioEngine.playMechanicalSound(MechanicalSoundType.PLAY_CLACK, _appSettings.value)
        playerController.playTrack(track, queue)
    }

    fun togglePlayPause() {
        val isCurrentlyPlaying = playbackState.value.isPlaying
        val type = if (isCurrentlyPlaying) MechanicalSoundType.PAUSE_CLICK else MechanicalSoundType.PLAY_CLACK
        audioEngine.playMechanicalSound(type, _appSettings.value)
        playerController.togglePlayPause()
    }

    fun skipToNext() {
        audioEngine.playMechanicalSound(MechanicalSoundType.SKIP_CLICK, _appSettings.value)
        playerController.skipToNext()
    }

    fun skipToPrevious() {
        audioEngine.playMechanicalSound(MechanicalSoundType.SKIP_CLICK, _appSettings.value)
        playerController.skipToPrevious()
    }

    fun seekTo(positionMs: Long) {
        playerController.seekTo(positionMs)
    }

    fun toggleFavorite(track: AudioTrack) {
        val nextFav = !track.isFavorite
        viewModelScope.launch(Dispatchers.IO) {
            database.songDao().updateFavorite(track.id, if (nextFav) 1 else 0)
        }
    }

    fun createPlaylist(name: String, colorAccent: Long = 0xFF1DF74B) {
        viewModelScope.launch(Dispatchers.IO) {
            val playlist = PlaylistEntity(
                id = UUID.randomUUID().toString(),
                name = name,
                createdAt = System.currentTimeMillis(),
                colorAccent = colorAccent,
                description = "Rewind Custom Mixtape"
            )
            database.playlistDao().insertPlaylist(playlist)
        }
    }

    fun addSongToPlaylist(playlistId: String, songId: String) {
        viewModelScope.launch(Dispatchers.IO) {
            val count = database.playlistDao().getPlaylistSongCount(playlistId)
            database.playlistDao().addSongToPlaylist(
                PlaylistSongCrossRef(playlistId, songId, count)
            )
        }
    }

    fun playMechanicalSound(type: MechanicalSoundType) {
        audioEngine.playMechanicalSound(type, _appSettings.value)
    }

    override fun onCleared() {
        super.onCleared()
        audioEngine.release()
        playerController.release()
    }
}
