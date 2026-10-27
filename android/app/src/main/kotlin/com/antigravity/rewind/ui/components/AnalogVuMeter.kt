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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.antigravity.rewind.ui.theme.TapeAmber
import com.antigravity.rewind.ui.theme.VinylRed
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun AnalogVuMeter(
    isPlaying: Boolean,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "VuTransition")
    val needleL by infiniteTransition.animateFloat(
        initialValue = 0.2f,
        targetValue = if (isPlaying) 0.85f else 0.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 380, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "NeedleLeft"
    )

    val needleR by infiniteTransition.animateFloat(
        initialValue = 0.15f,
        targetValue = if (isPlaying) 0.78f else 0.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 440, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "NeedleRight"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(54.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SingleVuChannel(label = "CH-L", value = needleL, modifier = Modifier.weight(1f))
        SingleVuChannel(label = "CH-R", value = needleR, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun SingleVuChannel(
    label: String,
    value: Float,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxHeight()
            .clip(RoundedCornerShape(6.dp))
            .background(Color(0xFFF3ECE0)) // Vintage warm cream parchment dial
            .border(1.dp, Color(0xFF383A42), RoundedCornerShape(6.dp))
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height
            val pivot = Offset(w * 0.5f, h * 1.15f)
            val needleLen = h * 0.95f

            // Scale arc marks (-20 dB to +3 dB)
            val startAngle = -140.0 * (PI / 180.0)
            val endAngle = -40.0 * (PI / 180.0)

            for (i in 0..10) {
                val frac = i / 10.0
                val angle = startAngle + frac * (endAngle - startAngle)
                val isRedZone = frac >= 0.75
                val color = if (isRedZone) VinylRed else Color(0xFF1E2024)

                val p1 = Offset(
                    (pivot.x + (needleLen * 0.88f * cos(angle))).toFloat(),
                    (pivot.y + (needleLen * 0.88f * sin(angle))).toFloat()
                )
                val p2 = Offset(
                    (pivot.x + (needleLen * cos(angle))).toFloat(),
                    (pivot.y + (needleLen * sin(angle))).toFloat()
                )
                drawLine(color = color, start = p1, end = p2, strokeWidth = 1.2.dp.toPx())
            }

            // Deflecting Needle
            val currentAngle = startAngle + (value.coerceIn(0f, 1f) * (endAngle - startAngle))
            val needleTip = Offset(
                (pivot.x + (needleLen * cos(currentAngle))).toFloat(),
                (pivot.y + (needleLen * sin(currentAngle))).toFloat()
            )
            drawLine(
                color = Color(0xFF1A1C20),
                start = pivot,
                end = needleTip,
                strokeWidth = 1.5.dp.toPx(),
                cap = StrokeCap.Round
            )
        }

        Text(
            text = label,
            color = Color(0xFF4A4D55),
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Bold,
            fontSize = 7.5.sp,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(4.dp)
        )
        Text(
            text = "VU",
            color = VinylRed,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Bold,
            fontSize = 7.5.sp,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(4.dp)
        )
    }
}
