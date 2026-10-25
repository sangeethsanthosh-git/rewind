import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'artwork_widget.dart';
import '../../features/audio_player/domain/audio_track.dart';

class CassetteTapeWidget extends StatefulWidget {
  final AudioTrack? track;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Color? labelColor;
  final bool isSideB;
  final bool isTransparentShell;

  const CassetteTapeWidget({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.labelColor,
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
    final isDarkLabel = effectiveLabelColor.computeLuminance() < 0.4;
    final textColor = isDarkLabel ? Colors.white : AppColors.textOnCream;

    final progress = widget.duration.inMilliseconds > 0
        ? (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return AspectRatio(
      aspectRatio: 1.58, // Standard compact audio cassette aspect ratio
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: widget.isTransparentShell
              ? const Color(0x402A303A)
              : const Color(0xFF1F1F24), // Shell plastic
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(190),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withAlpha(widget.isTransparentShell ? 45 : 15),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: widget.isTransparentShell ? const Color(0x65FFFFFF) : const Color(0xFF33333C),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Corner screws
            const Positioned(top: 10, left: 10, child: _ScrewHead()),
            const Positioned(top: 10, right: 10, child: _ScrewHead()),
            const Positioned(bottom: 12, left: 12, child: _ScrewHead()),
            const Positioned(bottom: 12, right: 12, child: _ScrewHead()),

            // Red guide pins in bottom corners (Reference Image 1)
            if (widget.isTransparentShell) ...[
              Positioned(
                bottom: 18,
                left: 36,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD33828),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                right: 36,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD33828),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],

            // Cassette center paper label
            Positioned(
              top: 24,
              left: 20,
              right: 20,
              bottom: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveLabelColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Top header row: Album Artwork, Side, Title, Label info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Printed promotional artwork thumbnail (Image on Cassette)
                        if (widget.track != null) ...[
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: textColor.withAlpha(100), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(80),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: ArtworkWidget(
                                id: int.tryParse(widget.track!.id),
                                albumId: widget.track!.albumId,
                                customArtPath: widget.track!.customArtPath,
                                type: ArtworkType.AUDIO,
                                size: 34,
                                borderRadius: 3,
                                title: widget.track!.title,
                                artist: widget.track!.artist,
                              ),
                            ),
                          ),
                        ],
                        // Side indicator stamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: textColor.withAlpha(160), width: 1.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.isSideB ? 'SIDE B' : 'SIDE A',
                            style: AppTypography.monoSmall.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Track title & artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.track?.title ?? 'NO CASSETTE LOADED',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cassetteHeader.copyWith(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                widget.track?.artist ?? 'Insert local audio track',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cassetteSub.copyWith(
                                  color: textColor.withAlpha(180),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Audio format badge
                        Text(
                          widget.track?.fileExtension.toUpperCase() ?? 'K7',
                          style: AppTypography.monoSmall.copyWith(
                            color: textColor.withAlpha(140),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Center tape window with rotating spools
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101014),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black.withAlpha(180), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left reel (shrinks as tape plays)
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                child: _CassetteSpool(
                                  tapeRadius: 20 * (1.0 - (progress * 0.5)),
                                ),
                              );
                            },
                          ),

                          // Center transparent window with counter gauge
                          Container(
                            width: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Magnetic tape ribbon bridge
                                Container(
                                  height: 12,
                                  color: const Color(0xFF3A2418), // Dark brown tape
                                ),
                                const SizedBox(height: 4),
                                // Ruler counter
                                Text(
                                  '100 • 50 • 0',
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 8,
                                    color: Colors.white.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right reel (grows as tape plays)
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                child: _CassetteSpool(
                                  tapeRadius: 10 + (progress * 10),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom info label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SPOOL ANALOG STEREO',
                          style: AppTypography.monoSmall.copyWith(
                            color: textColor.withAlpha(130),
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          'DOLBY B-C NR',
                          style: AppTypography.monoSmall.copyWith(
                            color: textColor.withAlpha(130),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom tape head cutout trapezoid
            Positioned(
              bottom: 0,
              left: 50,
              right: 50,
              height: 24,
              child: CustomPaint(
                painter: _TapeHeadCutoutPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrewHead extends StatelessWidget {
  const _ScrewHead();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6B6B76),
        border: Border.all(color: const Color(0xFF383840), width: 1),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 1.2,
          color: const Color(0xFF1E1E24),
        ),
      ),
    );
  }
}

class _CassetteSpool extends StatelessWidget {
  final double tapeRadius;

  const _CassetteSpool({required this.tapeRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2B1C14), // Dark brown wound tape roll
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // White plastic center cog
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 6 teeth cutouts
              for (int i = 0; i < 6; i++)
                Transform.rotate(
                  angle: (i * 60) * math.pi / 180,
                  child: Container(
                    width: 3.5,
                    height: 26,
                    color: Colors.black.withAlpha(40),
                  ),
                ),
              // Center hole
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF101014),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapeHeadCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF141418)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF33333C)
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
