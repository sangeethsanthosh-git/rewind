package com.antigravity.rewind.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.antigravity.rewind.model.AudioTrack
import com.antigravity.rewind.ui.theme.*
import java.io.File
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun CassetteTapeView(
    track: AudioTrack?,
    isPlaying: Boolean,
    progress: Float,
    modifier: Modifier = Modifier,
    isSideB: Boolean = false,
    accentColor: Color = RewindGreen
) {
    // Spool rotation: pauses when isPlaying is false to conserve battery
    val infiniteTransition = rememberInfiniteTransition(label = "SpoolRotation")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = if (isPlaying) 360f else 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 2400, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "SpoolRotationAngle"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(1.58f)
            .clip(RoundedCornerShape(12.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(Color(0xFF282A30), Color(0xFF141518), Color(0xFF0D0E10))
                )
            )
            .border(1.5.dp, Color(0xFF383A42), RoundedCornerShape(12.dp))
    ) {
        // Cassette J-Card Sticker Label
        Box(
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .fillMaxHeight(0.70f)
                .align(Alignment.Center)
                .clip(RoundedCornerShape(8.dp))
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color(0xFF24272E), Color(0xFF181A1F))
                    )
                )
                .border(1.dp, Color(0xFF3F434D), RoundedCornerShape(8.dp))
        ) {
            // Album Art Sticker Banner
            if (track?.customArtPath != null && File(track.customArtPath).exists()) {
                AsyncImage(
                    model = File(track.customArtPath),
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop,
                    alpha = 0.40f
                )
            }

            // Printed Header (Side, Title, Artist)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(3.dp))
                        .border(0.8.dp, accentColor.copy(alpha = 0.6f), RoundedCornerShape(3.dp))
                        .padding(horizontal = 5.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = if (isSideB) "SIDE B" else "SIDE A",
                        color = accentColor,
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.Bold,
                        fontSize = 9.sp
                    )
                }

                Spacer(modifier = Modifier.width(8.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = track?.title ?: "NO CASSETTE LOADED",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 11.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = track?.artist ?: "Local Audio Deck",
                        color = TextSecondary,
                        fontSize = 9.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // Center Recessed Spool Bay & Tape Window
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.82f)
                    .height(60.dp)
                    .align(Alignment.Center)
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color(0xFF0A0B0D))
                    .border(1.dp, Color(0xFF1E2026), RoundedCornerShape(6.dp))
            ) {
                // Spool Canvas (Left reel, right reel, tape ribbon, counter ruler)
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val w = size.width
                    val h = size.height
                    val spoolRadius = h * 0.40f
                    val leftCenter = Offset(w * 0.20f, h * 0.50f)
                    val rightCenter = Offset(w * 0.80f, h * 0.50f)

                    // Magnetic tape ribbon
                    drawRect(
                        brush = Brush.verticalGradient(
                            listOf(Color(0xFF261811), Color(0xFF3D261B), Color(0xFF261811))
                        ),
                        topLeft = Offset(0f, h * 0.42f),
                        size = androidx.compose.ui.geometry.Size(w, h * 0.16f)
                    )

                    // Tape wound on left spool (shrinks as song plays)
                    val leftTapeRadius = spoolRadius * (1.0f - (progress * 0.5f))
                    drawCircle(
                        color = Color(0xFF332016),
                        radius = leftTapeRadius,
                        center = leftCenter
                    )

                    // Tape wound on right spool (grows as song plays)
                    val rightTapeRadius = spoolRadius * (0.5f + (progress * 0.5f))
                    drawCircle(
                        color = Color(0xFF332016),
                        radius = rightTapeRadius,
                        center = rightCenter
                    )

                    // Draw rotating spools
                    rotate(rotation, leftCenter) {
                        drawSpoolHub(leftCenter, spoolRadius)
                    }
                    rotate(rotation, rightCenter) {
                        drawSpoolHub(rightCenter, spoolRadius)
                    }

                    // Center ruler tick marks
                    val markY1 = h * 0.32f
                    val markY2 = h * 0.68f
                    val centerX = w * 0.5f
                    for (i in -3..3) {
                        val markX = centerX + (i * 8.dp.toPx())
                        drawLine(
                            color = Color.White.copy(alpha = 0.3f),
                            start = Offset(markX, markY1),
                            end = Offset(markX, markY1 + 4.dp.toPx()),
                            strokeWidth = 1.dp.toPx()
                        )
                        drawLine(
                            color = Color.White.copy(alpha = 0.3f),
                            start = Offset(markX, markY2 - 4.dp.toPx()),
                            end = Offset(markX, markY2),
                            strokeWidth = 1.dp.toPx()
                        )
                    }
                }
            }

            // Bottom Printed Legend
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 4.dp)
                    .align(Alignment.BottomCenter),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "REWIND STEREO CASSETTE",
                    color = Color.White.copy(alpha = 0.5f),
                    fontFamily = FontFamily.Monospace,
                    fontSize = 7.5.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "TYPE II • HIGH BIAS",
                    color = Color.White.copy(alpha = 0.5f),
                    fontFamily = FontFamily.Monospace,
                    fontSize = 7.5.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

private fun DrawScope.drawSpoolHub(center: Offset, radius: Float) {
    // White circular hub
    drawCircle(
        color = Color(0xFFF0F0F2),
        radius = radius * 0.85f,
        center = center
    )
    drawCircle(
        color = Color(0xFF202226),
        radius = radius * 0.40f,
        center = center
    )

    // 6 gear drive spokes
    for (i in 0 until 6) {
        val angle = (i * 60.0) * (PI / 180.0)
        val spokeX = center.x + (radius * 0.55f * cos(angle)).toFloat()
        val spokeY = center.y + (radius * 0.55f * sin(angle)).toFloat()
        drawCircle(
            color = Color(0xFF383A42),
            radius = radius * 0.12f,
            center = Offset(spokeX, spokeY)
        )
    }
}
