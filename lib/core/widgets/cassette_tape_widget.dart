import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'artwork_widget.dart';
import '../../features/audio_player/domain/audio_track.dart';

/// Ultra-authentic compact audio cassette matching photo-realistic reference:
/// - Matte dark charcoal chassis with 5 Phillips screws (4 corners + center bottom).
/// - Lower beveled trapezoid zone with dual guide pin holes and capstan slots.
/// - Full-bleed printed cassette label sticker with chamfered top corners showing
///   the active track's album art / custom banner.
/// - Recessed dark center capsule housing dual rotating white 6-toothed spool hubs
///   and magnetic tape pack with counter gauge.
class CassetteTapeWidget extends StatefulWidget {
  final AudioTrack? track;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Color? labelColor;
  final Color? accentColor;
  final bool isSideB;
  final bool isTransparentShell;

  const CassetteTapeWidget({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.labelColor,
    this.accentColor,
    this.isSideB = false,
    this.isTransparentShell = false,
  });

  @override
  State<CassetteTapeWidget> createState() => _CassetteTapeWidgetState();
}

class _CassetteTapeWidgetState extends State<CassetteTapeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CassetteTapeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = widget.labelColor ?? AppColors.cassetteCream;
    final progress = widget.duration.inMilliseconds > 0
        ? (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final themeAccent = widget.accentColor ?? Theme.of(context).primaryColor;

    return AspectRatio(
      aspectRatio: 1.58, // Standard compact audio cassette aspect ratio
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Responsive measurements
          final screwSize = (h * 0.065).clamp(10.0, 15.0);
          final cornerInset = (h * 0.05).clamp(8.0, 13.0);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: widget.isTransparentShell
                  ? const Color(0x402A303A)
                  : const Color(0xFF212226), // Matte charcoal shell
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(210),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withAlpha(widget.isTransparentShell ? 45 : 18),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
              border: Border.all(
                color: widget.isTransparentShell
                    ? const Color(0x65FFFFFF)
                    : const Color(0xFF33353D),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // 1. Top & Bottom Corner Screws (4 corners)
                Positioned(
                  top: cornerInset,
                  left: cornerInset,
                  child: _ScrewHead(size: screwSize),
                ),
                Positioned(
                  top: cornerInset,
                  right: cornerInset,
                  child: _ScrewHead(size: screwSize),
                ),
                Positioned(
                  bottom: cornerInset + 2,
                  left: cornerInset + 2,
                  child: _ScrewHead(size: screwSize),
                ),
                Positioned(
                  bottom: cornerInset + 2,
                  right: cornerInset + 2,
                  child: _ScrewHead(size: screwSize),
                ),

                // 2. Full-bleed Printed Cassette Label Sticker
                Positioned(
                  top: h * 0.09,
                  left: w * 0.045,
                  right: w * 0.045,
                  bottom: h * 0.22,
                  child: ClipPath(
                    clipper: const _CassetteStickerClipper(chamfer: 14, radius: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: effectiveLabelColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(90),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // A. Album Art / Banner or Retro Paper Background
                          _buildStickerBackground(effectiveLabelColor, themeAccent),

                          // B. Subtle vintage paper gradient & vignette
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(35),
                                  Colors.transparent,
                                  Colors.black.withAlpha(60),
                                ],
                              ),
                            ),
                          ),

                          // C. Top printed information header
                          Positioned(
                            top: 8,
                            left: 12,
                            right: 12,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Side Stamp Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(140),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.white38, width: 0.8),
                                  ),
                                  child: Text(
                                    widget.isSideB ? 'SIDE B' : 'SIDE A',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 8.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Track Title & Artist Overlay
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.track?.title ?? 'NO CASSETTE LOADED',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        widget.track?.artist ?? 'Insert local audio track',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(210),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black,
                                              offset: Offset(0, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (w >= 280) ...[
                                  const SizedBox(width: 6),
                                  // Format / Dolby badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(120),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'DOLBY B-C NR • ${widget.track?.fileExtension.toUpperCase() ?? "K7"}',
                                      style: AppTypography.monoSmall.copyWith(
                                        color: Colors.white70,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // D. Center Recessed Capsule with Rotating Spool Hubs & Tape Window
                          Center(
                            child: _buildCenterTransportCapsule(w, h, progress),
                          ),

                          // E. Bottom printed label credits
                          Positioned(
                            bottom: 6,
                            left: 12,
                            right: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'REWIND STEREO CASSETTE',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoSmall.copyWith(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(color: Colors.black, blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'HIGH BIAS • TYPE II',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: AppTypography.monoSmall.copyWith(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      shadows: const [
                                        Shadow(color: Colors.black, blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Center Bottom Screw (positioned between sticker and bottom trapezoid)
                Positioned(
                  bottom: h * 0.165,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ScrewHead(size: screwSize),
                  ),
                ),

                // 4. Bottom Beveled Trapezoid with Tape Head & Guide Holes
                Positioned(
                  bottom: 0,
                  left: w * 0.12,
                  right: w * 0.12,
                  height: h * 0.14,
                  child: _buildBottomTrapezoidSection(h),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the background of the cassette label sticker.
  /// If track has custom banner or artwork, it covers the sticker with BoxFit.cover.
  Widget _buildStickerBackground(Color effectiveLabelColor, Color accentColor) {
    if (widget.track != null) {
      if (widget.track!.customArtPath != null &&
          widget.track!.customArtPath!.isNotEmpty &&
          File(widget.track!.customArtPath!).existsSync()) {
        return Image.file(
          File(widget.track!.customArtPath!),
          fit: BoxFit.cover,
        );
      }

      return ArtworkWidget(
        id: int.tryParse(widget.track!.id),
        albumId: widget.track!.albumId,
        customArtPath: widget.track!.customArtPath,
        type: ArtworkType.AUDIO,
        size: double.infinity,
        borderRadius: 0,
        title: widget.track!.title,
        artist: widget.track!.artist,
      );
    }

    // Fallback retro textured paper label
    return Container(
      color: effectiveLabelColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 4,
            color: accentColor,
          ),
          Container(
            height: 4,
            color: accentColor.withAlpha(180),
          ),
        ],
      ),
    );
  }

  /// Center dark capsule with dual 6-spoke white gear hubs and magnetic tape window
  Widget _buildCenterTransportCapsule(double w, double h, double progress) {
    final capsuleW = (w * 0.64).clamp(180.0, 240.0);
    final capsuleH = (h * 0.36).clamp(46.0, 56.0);
    final spoolSize = (capsuleH * 0.88).clamp(36.0, 48.0);

    return Container(
      width: capsuleW,
      height: capsuleH,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141518),
        borderRadius: BorderRadius.circular(capsuleH / 2),
        border: Border.all(color: const Color(0xFF2A2B30), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(200),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Spool Reel (shrinks as song plays, isolated behind RepaintBoundary)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: _CassetteSpool(
                    size: spoolSize,
                    tapeRadius: 20 * (1.0 - (progress * 0.5)),
                  ),
                );
              },
            ),
          ),

          // Center Tinted Window with Magnetic Tape Ribbon & Tape Counter Gauge
          Expanded(
            child: Container(
              height: capsuleH * 0.68,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1012),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF222328), width: 1.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Magnetic tape ribbon running across
                  Container(
                    height: 11,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF20130C),
                          Color(0xFF382317),
                          Color(0xFF20130C),
                        ],
                      ),
                    ),
                  ),
                  // Vintage tape counter ruler: tick marks & gauge
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top tick marks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          7,
                          (i) => Container(
                            width: 1,
                            height: 3,
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
                      ),
                      // Center counter readout
                      Text(
                        '100 \u2022 50 \u2022 0',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withAlpha(170),
                          letterSpacing: 0.8,
                        ),
                      ),
                      // Bottom tick marks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          7,
                          (i) => Container(
                            width: 1,
                            height: 3,
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Spool Reel (grows as song plays, isolated behind RepaintBoundary)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: _CassetteSpool(
                    size: spoolSize,
                    tapeRadius: 10 + (progress * 10),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom beveled trapezoid with realistic guide pin holes & capstan roller cutouts
  Widget _buildBottomTrapezoidSection(double h) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Trapezoid bevel background
        CustomPaint(
          size: Size.infinite,
          painter: _TapeHeadCutoutPainter(),
        ),

        // 4 Cutout Holes: Circle, Rect, Rect, Circle
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 14, right: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left circular guide pin hole
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C0C0E),
                  border: Border.all(color: const Color(0xFF2C2D33), width: 0.8),
                ),
              ),

              // Left rectangular capstan slot
              Container(
                width: 9,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: const Color(0xFF0C0C0E),
                  border: Border.all(color: const Color(0xFF2C2D33), width: 0.8),
                ),
              ),

              const SizedBox(width: 20), // Spacing for center screw above

              // Right rectangular capstan slot
              Container(
                width: 9,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: const Color(0xFF0C0C0E),
                  border: Border.all(color: const Color(0xFF2C2D33), width: 0.8),
                ),
              ),

              // Right circular guide pin hole
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C0C0E),
                  border: Border.all(color: const Color(0xFF2C2D33), width: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Classic Audio Cassette Sticker shape with 45-degree chamfered top corners
/// and rounded bottom corners.
class _CassetteStickerClipper extends CustomClipper<Path> {
  final double chamfer;
  final double radius;

  const _CassetteStickerClipper({this.chamfer = 14, this.radius = 8});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(chamfer, 0);
    path.lineTo(size.width - chamfer, 0);
    path.lineTo(size.width, chamfer);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, chamfer);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Realistic Metallic Phillips Screw Head with recessed bevel
class _ScrewHead extends StatelessWidget {
  final double size;
  const _ScrewHead({this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF191A1D),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x20FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -0.5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.76,
          height: size * 0.76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6E7179),
                Color(0xFF45474D),
                Color(0xFF2D2F33),
              ],
            ),
            border: Border.all(color: const Color(0xFF25262A), width: 0.8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Phillips cross horizontal slot
              Container(
                width: size * 0.44,
                height: 1.3,
                decoration: BoxDecoration(
                  color: const Color(0xFF131416),
                  borderRadius: BorderRadius.circular(0.4),
                ),
              ),
              // Phillips cross vertical slot
              Container(
                width: 1.3,
                height: size * 0.44,
                decoration: BoxDecoration(
                  color: const Color(0xFF131416),
                  borderRadius: BorderRadius.circular(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Realistic white 6-toothed spool gear hub with wound magnetic tape pack
class _CassetteSpool extends StatelessWidget {
  final double tapeRadius;
  final double size;

  const _CassetteSpool({required this.tapeRadius, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final safeTapeSize = math.max(size * 0.75, (tapeRadius * 2).clamp(size * 0.75, size));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wound brown magnetic tape roll behind the white cog hub
          Container(
            width: safeTapeSize,
            height: safeTapeSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFF1B110B),
                  Color(0xFF332014),
                  Color(0xFF20130C),
                ],
              ),
            ),
          ),

          // White plastic 6-toothed cog hub
          CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: _SpoolHubPainter(),
          ),

          // Hollow center spindle hole (dark chassis depth)
          Container(
            width: size * 0.26,
            height: size * 0.26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0F1012),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the white 6-toothed cog wheel
class _SpoolHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // White plastic disk
    final whitePaint = Paint()
      ..color = const Color(0xFFF3F3F5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, whitePaint);

    // 6 gear tooth cutouts around rim
    final cutoutPaint = Paint()
      ..color = const Color(0xFF141518)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final toothPath = Path();
      final toothRadius = radius * 0.95;
      final x1 = center.dx + math.cos(angle - 0.22) * toothRadius;
      final y1 = center.dy + math.sin(angle - 0.22) * toothRadius;
      final x2 = center.dx + math.cos(angle + 0.22) * toothRadius;
      final y2 = center.dy + math.sin(angle + 0.22) * toothRadius;
      final xIn = center.dx + math.cos(angle) * (radius * 0.62);
      final yIn = center.dy + math.sin(angle) * (radius * 0.62);

      toothPath.moveTo(x1, y1);
      toothPath.lineTo(xIn, yIn);
      toothPath.lineTo(x2, y2);
      toothPath.close();

      canvas.drawPath(toothPath, cutoutPaint);
    }

    // Inner rim line
    final rimPaint = Paint()
      ..color = const Color(0xFFDDDEE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.60, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the bottom trapezoid cutout for the tape head
class _TapeHeadCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF17181B)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2F3037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(14, 0)
      ..lineTo(size.width - 14, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
