package com.antigravity.rewind.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.antigravity.rewind.model.AppSettings
import com.antigravity.rewind.ui.theme.*

@Composable
fun SettingsScreen(
    appSettings: AppSettings,
    accentColor: Color,
    onUpdateSettings: (AppSettings) -> Unit,
    onRescanLibrary: () -> Unit,
    onNavigateToCodecDiagnostics: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Obsidian)
            .padding(horizontal = 16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "SYSTEM SETUP • PREFERENCES",
            color = Color.White,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Black,
            fontSize = 18.sp,
            letterSpacing = 2.sp
        )
        Text(
            text = "HARDWARE TUNING & RETRO WALKMAN OPTIONS",
            color = TextMuted,
            fontFamily = FontFamily.Monospace,
            fontSize = 9.sp
        )

        Spacer(modifier = Modifier.height(18.dp))

        // SECTION: ACCENT THEME
        SettingsSectionHeader(title = "ACCENT BRANDING COLOR")
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            val swatches = listOf(
                0xFF1DF74B to "Rewind Green",
                0xFFFF5E36 to "Neon Orange",
                0xFF00E5FF to "Electric Cyan",
                0xFFFF1493 to "Hot Magenta",
                0xFFFFB300 to "Spool Gold"
            )

            swatches.forEach { (colorVal, _) ->
                val isSelected = appSettings.accentColorValue == colorVal
                Box(
                    modifier = Modifier
                        .size(42.dp)
                        .clip(RoundedCornerShape(21.dp))
                        .background(Color(colorVal))
                        .clickable {
                            onUpdateSettings(appSettings.copy(accentColorValue = colorVal))
                        },
                    contentAlignment = Alignment.Center
                ) {
                    if (isSelected) {
                        Icon(Icons.Default.Check, contentDescription = null, tint = Color.Black)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // SECTION: MECHANICAL AUDIO FEEDBACK
        SettingsSectionHeader(title = "MECHANICAL AUDIO & SOUNDPOOL")
        SettingsCard {
            SettingsToggleItem(
                title = "Mechanical Button Clicks",
                subtitle = "Crisp analog key clack via low-latency SoundPool",
                checked = appSettings.enableMechanicalSounds,
                accentColor = accentColor,
                onCheckedChange = { onUpdateSettings(appSettings.copy(enableMechanicalSounds = it)) }
            )
            HorizontalDivider(color = BorderSubtle, thickness = 0.6.dp)
            SettingsToggleItem(
                title = "Cassette Insert / Latch Sounds",
                subtitle = "Authentic tape insertion and bay latching audio",
                checked = appSettings.enableCassetteSounds,
                accentColor = accentColor,
                onCheckedChange = { onUpdateSettings(appSettings.copy(enableCassetteSounds = it)) }
            )
            HorizontalDivider(color = BorderSubtle, thickness = 0.6.dp)
            SettingsToggleItem(
                title = "DC Capstan Motor Hum",
                subtitle = "Faint analog transport motor ambience during playback",
                checked = appSettings.enableMotorAmbience,
                accentColor = accentColor,
                onCheckedChange = { onUpdateSettings(appSettings.copy(enableMotorAmbience = it)) }
            )
            HorizontalDivider(color = BorderSubtle, thickness = 0.6.dp)
            SettingsToggleItem(
                title = "Tactile Haptic Feedback",
                subtitle = "Subtle vibration pulse when depressing keys",
                checked = appSettings.enableHaptics,
                accentColor = accentColor,
                onCheckedChange = { onUpdateSettings(appSettings.copy(enableHaptics = it)) }
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // SECTION: AUDIO ENGINE & CODECS
        SettingsSectionHeader(title = "AUDIO ENGINE & HARDWARE CODECS")
        SettingsCard {
            SettingsClickableItem(
                icon = Icons.Default.Memory,
                title = "Hardware Codec Diagnostics",
                subtitle = "Inspect device MediaCodecList & hardware acceleration",
                onClick = onNavigateToCodecDiagnostics
            )
            HorizontalDivider(color = BorderSubtle, thickness = 0.6.dp)
            SettingsToggleItem(
                title = "Gapless Playback",
                subtitle = "Continuous transition without silent gaps between tracks",
                checked = appSettings.gaplessPlayback,
                accentColor = accentColor,
                onCheckedChange = { onUpdateSettings(appSettings.copy(gaplessPlayback = it)) }
            )
            HorizontalDivider(color = BorderSubtle, thickness = 0.6.dp)
            SettingsClickableItem(
                icon = Icons.Default.Refresh,
                title = "Rescan Media Library",
                subtitle = "Discover new audio files on internal storage and microSD",
                onClick = onRescanLibrary
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // SECTION: PRIVACY GUARANTEE
        SettingsCard {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Security, contentDescription = null, tint = RewindGreen)
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text("100% Offline Guarantee", fontWeight = FontWeight.Bold, color = TextPrimary, fontSize = 13.sp)
                    Text(
                        "Rewind runs entirely locally on your device. Zero analytics, no telemetry, no tracking, and no internet required.",
                        color = TextMuted,
                        fontSize = 10.5.sp
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "REWIND v2.0.0 • NATIVE KOTLIN EDITION",
                color = TextMuted,
                fontFamily = FontFamily.Monospace,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Pure AndroidX Media3 • Jetpack Compose • 100% Offline",
                color = TextSecondary,
                fontSize = 9.5.sp
            )
        }

        Spacer(modifier = Modifier.height(130.dp))
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        color = TextMuted,
        fontFamily = FontFamily.Monospace,
        fontSize = 10.sp,
        letterSpacing = 1.4.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
private fun SettingsCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceCard)
            .border(0.8.dp, BorderSubtle, RoundedCornerShape(12.dp)),
        content = content
    )
}

@Composable
private fun SettingsToggleItem(
    title: String,
    subtitle: String,
    checked: Boolean,
    accentColor: Color,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            Text(subtitle, color = TextMuted, fontSize = 10.5.sp)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.Black,
                checkedTrackColor = accentColor,
                uncheckedTrackColor = SurfaceElevated
            )
        )
    }
}

@Composable
private fun SettingsClickableItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(24.dp))
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            Text(subtitle, color = TextMuted, fontSize = 10.5.sp)
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = TextMuted)
    }
}
