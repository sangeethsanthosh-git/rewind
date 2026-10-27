package com.antigravity.rewind.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.antigravity.rewind.model.AppSettings
import com.antigravity.rewind.model.AudioTrack
import com.antigravity.rewind.model.PlaybackState
import com.antigravity.rewind.playback.MechanicalSoundType
import com.antigravity.rewind.ui.components.CassetteTapeView
import com.antigravity.rewind.ui.components.MechanicalButton
import com.antigravity.rewind.ui.theme.*
import java.io.File

@Composable
fun WalkmanScreen(
    playbackState: PlaybackState,
    appSettings: AppSettings,
    accentColor: Color,
    onPlayPause: () -> Unit,
    onSkipNext: () -> Unit,
    onSkipPrevious: () -> Unit,
    onPlayMechanicalSound: (MechanicalSoundType) -> Unit,
    onUpdateSettings: (AppSettings) -> Unit
) {
    // 0: Closed, 1: Door Open, 2: Tape Loaded & Bay Open, 3: Door Closed & Tape Playing
    var step by remember { mutableIntStateOf(if (playbackState.currentTrack != null) 3 else 0) }
    var showCustomizer by remember { mutableStateOf(false) }

    // Auto-load if playing
    LaunchedEffect(playbackState.currentTrack) {
        if (playbackState.currentTrack != null && step == 0) {
            step = 3
        }
    }

    val doorAngle by animateFloatAsState(
        targetValue = if (step == 1 || step == 2) -140f else 0f,
        animationSpec = tween(durationMillis = 650),
        label = "DoorAngle"
    )

    // Chassis Theme Resolution
    val chassisBrush = remember(appSettings.walkmanChassisTheme, appSettings.accentColorValue) {
        when (appSettings.walkmanChassisTheme) {
            "stealthBlack" -> Brush.verticalGradient(listOf(WalkmanBlack, Color(0xFF101114)))
            "solarYellow" -> Brush.verticalGradient(listOf(WalkmanYellow, Color(0xFFC79815)))
            "vintageSilver" -> Brush.verticalGradient(listOf(WalkmanSilver, Color(0xFF8E939E)))
            "tokyoBurgundy" -> Brush.verticalGradient(listOf(WalkmanBurgundy, Color(0xFF38101F)))
            "customAccent" -> Brush.verticalGradient(listOf(Color(appSettings.accentColorValue), Color.Black))
            else -> Brush.verticalGradient(listOf(WalkmanBlue, WalkmanBlueDark)) // Classic Blue
        }
    }

    val currentTrack = playbackState.currentTrack
    val progress = if (playbackState.durationMs > 0) {
        (playbackState.positionMs.toFloat() / playbackState.durationMs.toFloat()).coerceIn(0f, 1f)
    } else 0f

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Obsidian)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(12.dp))

            // Header Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "PORTABLE STEREO CASSETTE PLAYER",
                    color = TextMuted,
                    fontFamily = FontFamily.Monospace,
                    fontSize = 10.sp,
                    letterSpacing = 1.4.sp
                )

                IconButton(onClick = {
                    onPlayMechanicalSound(MechanicalSoundType.SKIP_CLICK)
                    showCustomizer = true
                }) {
                    Icon(
                        imageVector = Icons.Default.Palette,
                        contentDescription = "Customize Walkman",
                        tint = accentColor
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Walkman Body Shell
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .clip(RoundedCornerShape(16.dp))
                    .background(chassisBrush)
                    .border(2.dp, Color(0xFF454B57), RoundedCornerShape(16.dp))
                    .padding(14.dp)
            ) {
                // Custom Skin Layer if set
                if (appSettings.walkmanCustomSkinPath != null && File(appSettings.walkmanCustomSkinPath).exists()) {
                    AsyncImage(
                        model = File(appSettings.walkmanCustomSkinPath),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(RoundedCornerShape(12.dp)),
                        alpha = 0.50f
                    )
                }

                Column(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    // Walkman Brand Plate & Status LED
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = appSettings.walkmanBrandingText,
                            color = Color.White,
                            fontWeight = FontWeight.Black,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 16.sp,
                            letterSpacing = 3.sp
                        )

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(if (playbackState.isPlaying) RewindGreen else VinylRed)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (playbackState.isPlaying) "TAPE RUN" else "STANDBY",
                                color = if (playbackState.isPlaying) RewindGreen else TextMuted,
                                fontFamily = FontFamily.Monospace,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    // Cassette Bay & Hinged Inspection Door
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f)
                            .padding(vertical = 12.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0xFF0C0D0F))
                            .border(1.5.dp, Color(0xFF262830), RoundedCornerShape(10.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        // The Cassette Tape inside the Bay
                        if (step >= 2) {
                            CassetteTapeView(
                                track = currentTrack,
                                isPlaying = playbackState.isPlaying,
                                progress = progress,
                                accentColor = accentColor,
                                modifier = Modifier
                                    .fillMaxWidth(0.92f)
                                    .padding(8.dp)
                            )
                        } else {
                            Text(
                                text = "CASSETTE BAY EMPTY\nTAP EJECT TO LOAD TAPE",
                                color = TextMuted,
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                                fontFamily = FontFamily.Monospace,
                                fontSize = 11.sp
                            )
                        }

                        // Acrylic Hinged Door with 3D Rotation
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .graphicsLayer {
                                    rotationY = doorAngle
                                    cameraDistance = 16f
                                }
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0x35FFFFFF)) // Clear transparent acrylic glass
                                .border(1.dp, Color(0x60FFFFFF), RoundedCornerShape(10.dp))
                        )
                    }

                    // Physical Mechanical Control Deck
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        MechanicalButton(
                            label = "REW",
                            icon = Icons.Default.FastRewind,
                            onClick = onSkipPrevious,
                            modifier = Modifier.weight(1f)
                        )
                        MechanicalButton(
                            label = if (playbackState.isPlaying) "PAUSE" else "PLAY",
                            icon = if (playbackState.isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            onClick = onPlayPause,
                            accentColor = accentColor,
                            isActive = playbackState.isPlaying,
                            modifier = Modifier.weight(1.3f)
                        )
                        MechanicalButton(
                            label = "FWD",
                            icon = Icons.Default.FastForward,
                            onClick = onSkipNext,
                            modifier = Modifier.weight(1f)
                        )
                        MechanicalButton(
                            label = "STOP",
                            icon = Icons.Default.Stop,
                            onClick = {
                                if (playbackState.isPlaying) onPlayPause()
                                onPlayMechanicalSound(MechanicalSoundType.PAUSE_CLICK)
                            },
                            modifier = Modifier.weight(1f)
                        )
                        MechanicalButton(
                            label = "EJECT",
                            icon = Icons.Default.Eject,
                            onClick = {
                                onPlayMechanicalSound(
                                    if (step == 1 || step == 2) MechanicalSoundType.DOOR_LATCH else MechanicalSoundType.CASSETTE_EJECT
                                )
                                step = if (step == 3 || step == 0) 1 else 3
                            },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(110.dp))
        }
    }

    if (showCustomizer) {
        WalkmanCustomizerDialog(
            currentTheme = appSettings.walkmanChassisTheme,
            currentBranding = appSettings.walkmanBrandingText,
            onSelectTheme = { themeKey ->
                onUpdateSettings(appSettings.copy(walkmanChassisTheme = themeKey))
            },
            onSelectBranding = { branding ->
                onUpdateSettings(appSettings.copy(walkmanBrandingText = branding))
            },
            onDismiss = { showCustomizer = false }
        )
    }
}

@Composable
private fun WalkmanCustomizerDialog(
    currentTheme: String,
    currentBranding: String,
    onSelectTheme: (String) -> Unit,
    onSelectBranding: (String) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                "WALKMAN CUSTOMIZER",
                fontFamily = FontFamily.Monospace,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = TextPrimary
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("CHASSIS FINISH", color = TextSecondary, fontFamily = FontFamily.Monospace, fontSize = 10.sp)

                val themes = listOf(
                    "classicBlue" to "Classic Blue",
                    "stealthBlack" to "Stealth Black",
                    "solarYellow" to "Solar Yellow",
                    "vintageSilver" to "Vintage Silver",
                    "tokyoBurgundy" to "Tokyo Burgundy",
                    "customAccent" to "Accent Color"
                )

                themes.forEach { (key, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (currentTheme == key) Color(0xFF2C2F38) else SurfaceCard)
                            .clickable { onSelectTheme(key) }
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = currentTheme == key,
                            onClick = { onSelectTheme(key) },
                            colors = RadioButtonDefaults.colors(selectedColor = RewindGreen)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(label, color = TextPrimary, fontSize = 13.sp)
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))
                Text("BRANDING EMBOSS", color = TextSecondary, fontFamily = FontFamily.Monospace, fontSize = 10.sp)

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("SONY", "REWIND", "TPS-L2").forEach { brand ->
                        FilterChip(
                            selected = currentBranding == brand,
                            onClick = { onSelectBranding(brand) },
                            label = { Text(brand, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = RewindGreen,
                                selectedLabelColor = Color.Black
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("DONE", color = RewindGreen, fontWeight = FontWeight.Bold)
            }
        },
        containerColor = SurfaceElevated
    )
}
