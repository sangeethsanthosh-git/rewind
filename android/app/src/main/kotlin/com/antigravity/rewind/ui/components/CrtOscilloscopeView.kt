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
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.antigravity.rewind.ui.theme.PhosphorGreen
import kotlin.math.PI
import kotlin.math.sin

@Composable
fun CrtOscilloscopeView(
    isPlaying: Boolean,
    modifier: Modifier = Modifier,
    beamColor: Color = PhosphorGreen
) {
    val infiniteTransition = rememberInfiniteTransition(label = "CrtTransition")
    val phase by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = if (isPlaying) (2 * PI).toFloat() else 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1400, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "CrtPhase"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(72.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0xFF070B08))
            .border(1.2.dp, Color(0xFF1B2A1E), RoundedCornerShape(8.dp))
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height

            // CRT phosphor reticle grid
            val gridStepX = w / 8f
            val gridStepY = h / 4f
            for (i in 1..7) {
                drawLine(
                    color = Color(0xFF0F2013),
                    start = Offset(i * gridStepX, 0f),
                    end = Offset(i * gridStepX, h),
                    strokeWidth = 1.dp.toPx()
                )
            }
            for (i in 1..3) {
                drawLine(
                    color = Color(0xFF0F2013),
                    start = Offset(0f, i * gridStepY),
                    end = Offset(w, i * gridStepY),
                    strokeWidth = 1.dp.toPx()
                )
            }

            // Oscilloscope Beam
            val path = Path()
            val centerY = h / 2f
            val amplitude = if (isPlaying) h * 0.32f else 2f

            for (x in 0..w.toInt() step 3) {
                val xNorm = x / w
                val y = centerY + amplitude * sin((xNorm * 4 * PI + phase).toFloat()) *
                        sin((xNorm * 2 * PI).toFloat())
                if (x == 0) path.moveTo(x.toFloat(), y) else path.lineTo(x.toFloat(), y)
            }

            // Glow trace
            drawPath(
                path = path,
                color = beamColor.copy(alpha = if (isPlaying) 0.35f else 0.15f),
                style = Stroke(width = 4.dp.toPx())
            )
            // Crisp center beam
            drawPath(
                path = path,
                color = beamColor,
                style = Stroke(width = 1.5.dp.toPx())
            )
        }

        Text(
            text = "CRT OSCILLOSCOPE • 10 kHz",
            color = beamColor.copy(alpha = 0.5f),
            fontFamily = FontFamily.Monospace,
            fontSize = 7.5.sp,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(6.dp)
        )
    }
}
