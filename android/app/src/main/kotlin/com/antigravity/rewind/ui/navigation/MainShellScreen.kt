package com.antigravity.rewind.ui.navigation

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.antigravity.rewind.model.AudioTrack
import com.antigravity.rewind.playback.MechanicalSoundType
import com.antigravity.rewind.ui.components.AlbumArtworkView
import com.antigravity.rewind.ui.screens.*
import com.antigravity.rewind.ui.theme.*
import com.antigravity.rewind.ui.viewmodel.MainViewModel

enum class NavigationTab(val label: String, val icon: ImageVector) {
    HOME("HOME", Icons.Default.Home),
    TAPES("TAPES", Icons.Default.LibraryMusic),
    WALKMAN("WALKMAN", Icons.Default.Radio),
    DISCS("DISCS", Icons.Default.Album),
    SETUP("SETUP", Icons.Default.Tune)
}

@Composable
fun MainShellScreen(viewModel: MainViewModel) {
    val songs by viewModel.songs.collectAsStateWithLifecycle()
    val albums by viewModel.albums.collectAsStateWithLifecycle()
    val artists by viewModel.artists.collectAsStateWithLifecycle()
    val playlists by viewModel.playlists.collectAsStateWithLifecycle()
    val folders by viewModel.folders.collectAsStateWithLifecycle()
    val playbackState by viewModel.playbackState.collectAsStateWithLifecycle()
    val appSettings by viewModel.appSettings.collectAsStateWithLifecycle()

    val accentColor = Color(appSettings.accentColorValue)

    var currentTab by remember { mutableStateOf(NavigationTab.HOME) }
    var isNowPlayingVisible by remember { mutableStateOf(false) }
    var isCodecDiagnosticsVisible by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Obsidian)
    ) {
        // Main Tab Content
        when (currentTab) {
            NavigationTab.HOME -> HomeScreen(
                songs = songs,
                currentTrack = playbackState.currentTrack,
                isPlaying = playbackState.isPlaying,
                accentColor = accentColor,
                onTrackClick = { track ->
                    viewModel.playTrack(track, songs)
                },
                onNavigateToNowPlaying = { isNowPlayingVisible = true }
            )
            NavigationTab.TAPES -> LibraryScreen(
                songs = songs,
                albums = albums,
                artists = artists,
                playlists = playlists,
                currentTrackId = playbackState.currentTrack?.id,
                accentColor = accentColor,
                onTrackClick = { track ->
                    viewModel.playTrack(track, songs)
                },
                onAlbumClick = {},
                onFavoriteToggle = { viewModel.toggleFavorite(it) },
                onCreatePlaylist = { viewModel.createPlaylist(it) }
            )
            NavigationTab.WALKMAN -> WalkmanScreen(
                playbackState = playbackState,
                appSettings = appSettings,
                accentColor = accentColor,
                onPlayPause = { viewModel.togglePlayPause() },
                onSkipNext = { viewModel.skipToNext() },
                onSkipPrevious = { viewModel.skipToPrevious() },
                onPlayMechanicalSound = { viewModel.playMechanicalSound(it) },
                onUpdateSettings = { viewModel.updateSettings(it) }
            )
            NavigationTab.DISCS -> FoldersScreen(
                folders = folders,
                accentColor = accentColor,
                onFolderClick = {}
            )
            NavigationTab.SETUP -> SettingsScreen(
                appSettings = appSettings,
                accentColor = accentColor,
                onUpdateSettings = { viewModel.updateSettings(it) },
                onRescanLibrary = { viewModel.scanMedia() },
                onNavigateToCodecDiagnostics = { isCodecDiagnosticsVisible = true }
            )
        }

        // Floating Retro Now Playing Banner on Home screen
        if (playbackState.currentTrack != null && currentTab == NavigationTab.HOME) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 68.dp, start = 12.dp, end = 12.dp)
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(SurfaceElevated)
                    .border(1.dp, BorderSubtle, RoundedCornerShape(12.dp))
                    .clickable { isNowPlayingVisible = true }
                    .padding(8.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val track = playbackState.currentTrack!!
                    AlbumArtworkView(
                        customArtPath = track.customArtPath,
                        contentUri = track.uri,
                        size = 42.dp,
                        cornerRadius = 6.dp
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = track.title,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.5.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = track.artist,
                            color = TextMuted,
                            fontSize = 10.5.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    IconButton(onClick = { viewModel.togglePlayPause() }) {
                        Icon(
                            imageVector = if (playbackState.isPlaying) Icons.Default.PauseCircle else Icons.Default.PlayCircle,
                            contentDescription = "Play/Pause",
                            tint = accentColor,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
            }
        }

        // Bottom Navigation Bar
        NavigationBar(
            containerColor = DarkCharcoal,
            contentColor = TextPrimary,
            tonalElevation = 8.dp,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .border(0.8.dp, BorderSubtle)
        ) {
            NavigationTab.values().forEach { tab ->
                val isSelected = currentTab == tab
                NavigationBarItem(
                    selected = isSelected,
                    onClick = {
                        viewModel.playMechanicalSound(MechanicalSoundType.SKIP_CLICK)
                        currentTab = tab
                    },
                    icon = {
                        Icon(
                            imageVector = tab.icon,
                            contentDescription = tab.label,
                            tint = if (isSelected) accentColor else TextMuted
                        )
                    },
                    label = {
                        Text(
                            text = tab.label,
                            fontFamily = FontFamily.Monospace,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                            fontSize = 9.sp,
                            color = if (isSelected) accentColor else TextMuted
                        )
                    },
                    colors = NavigationBarItemDefaults.colors(
                        indicatorColor = Color.Transparent
                    )
                )
            }
        }

        // Full Now Playing Modal Screen
        AnimatedVisibility(
            visible = isNowPlayingVisible,
            enter = slideInVertically(initialOffsetY = { it }),
            exit = slideOutVertically(targetOffsetY = { it })
        ) {
            NowPlayingScreen(
                playbackState = playbackState,
                accentColor = accentColor,
                onPlayPause = { viewModel.togglePlayPause() },
                onSkipNext = { viewModel.skipToNext() },
                onSkipPrevious = { viewModel.skipToPrevious() },
                onSeekTo = { viewModel.seekTo(it) },
                onToggleShuffle = { viewModel.playerController.toggleShuffle() },
                onToggleRepeat = { viewModel.playerController.toggleRepeat() },
                onDismiss = { isNowPlayingVisible = false }
            )
        }

        // Codec Diagnostics Screen
        AnimatedVisibility(
            visible = isCodecDiagnosticsVisible,
            enter = slideInHorizontally(initialOffsetX = { it }),
            exit = slideOutHorizontally(targetOffsetX = { it })
        ) {
            CodecDiagnosticsScreen(
                onNavigateBack = { isCodecDiagnosticsVisible = false }
            )
        }
    }
}
