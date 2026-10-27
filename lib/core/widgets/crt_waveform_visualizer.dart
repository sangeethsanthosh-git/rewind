import 'dart:math' as math;
import 'package:flutter/material.dart';

class CrtWaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final Color beamColor;

  const CrtWaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.height = 70,
    this.beamColor = const Color(0xFF00FF88), // Classic phosphor green
  });

  @override
  State<CrtWaveformVisualizer> createState() => _CrtWaveformVisualizerState();
}

class _CrtWaveformVisualizerState extends State<CrtWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPlaying) {
      _anim.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CrtWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (!_anim.isAnimating) _anim.repeat();
      } else {
        if (_anim.isAnimating) _anim.stop();
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF070B08), // Dark CRT glass
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1B2A1E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.beamColor.withAlpha(widget.isPlaying ? 25 : 8),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // CRT Grid Reticle
            CustomPaint(
              size: Size.infinite,
              painter: _CrtGridPainter(),
            ),

            // Oscilloscope Beam
            AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _WaveformPainter(
                    phase: _anim.value * 2 * math.pi,
                    isPlaying: widget.isPlaying,
                    beamColor: widget.beamColor,
                  ),
                );
              },
            ),

            // Scanlines Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScanlinePainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final bool isPlaying;
  final Color beamColor;

  _WaveformPainter({
    required this.phase,
    required this.isPlaying,
    required this.beamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path();
    path.moveTo(0, midY);

    final points = 80;
    final dx = size.width / points;

    for (int i = 0; i <= points; i++) {
      final x = i * dx;
      double y;
      if (isPlaying) {
        // Multi-frequency harmonic wave with modulation
        final normalizedX = i / points;
        final envelope = math.sin(normalizedX * math.pi); // Fade at edges
        final wave1 = math.sin((normalizedX * 12) + phase) * (size.height * 0.28);
        final wave2 = math.cos((normalizedX * 24) - phase * 1.5) * (size.height * 0.12);
        final wave3 = math.sin((normalizedX * 6) + phase * 0.7) * (size.height * 0.16);

        y = midY + (wave1 + wave2 + wave3) * envelope;
      } else {
        // Subtle resting baseline breathing
        final subtleWave = math.sin((i / points * 4) + phase * 0.3) * 1.5;
        y = midY + subtleWave;
      }
      path.lineTo(x, y);
    }

    // Glow beam
    final glowPaint = Paint()
      ..color = beamColor.withAlpha(isPlaying ? 90 : 30)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // Sharp center beam
    final corePaint = Paint()
      ..color = isPlaying ? Colors.white : beamColor.withAlpha(180)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

class _CrtGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF0F1E12)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    const hDivisions = 4;
    for (int i = 1; i < hDivisions; i++) {
      final y = size.height * (i / hDivisions);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    const vDivisions = 8;
    for (int i = 1; i < vDivisions; i++) {
      final x = size.width * (i / vDivisions);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withAlpha(45)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
