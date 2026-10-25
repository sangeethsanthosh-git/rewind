import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_typography.dart';
import '../services/mechanical_sound_service.dart';
import '../utils/formatters.dart';
import '../../features/audio_player/presentation/providers/audio_player_provider.dart';
import '../../features/audio_player/presentation/screens/now_playing_screen.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

/// Pixel-perfect retro portable cassette audio recorder / Walkman widget
/// modeled directly after the Braun / Teenage Engineering vintage physical aesthetic.
class RetroWalkmanWidget extends ConsumerStatefulWidget {
  final VoidCallback? onOpenNowPlaying;
  final bool compact;

  const RetroWalkmanWidget({
    super.key,
    this.onOpenNowPlaying,
    this.compact = false,
  });

  @override
  ConsumerState<RetroWalkmanWidget> createState() => _RetroWalkmanWidgetState();
}

class _RetroWalkmanWidgetState extends ConsumerState<RetroWalkmanWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveformController;
  final math.Random _random = math.Random(42);

  // Pre-generated static waveform base envelope
  late final List<double> _baseWaveform;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 32-bar waveform envelope
    _baseWaveform = List.generate(32, (i) {
      final normalized = (i - 16).abs() / 16.0;
      final bell = math.exp(-normalized * normalized * 2.5);
      return (bell * 0.75 + (_random.nextDouble() * 0.25)).clamp(0.12, 0.95);
    });
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  void _triggerHapticAndSound(MechanicalSoundType soundType) {
    HapticFeedback.lightImpact();
    MechanicalSoundService.instance.playMechanicalSound(
      soundType,
      settings: ref.read(settingsNotifierProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final currentTrack = playbackState.currentTrack;
    final isPlaying = playbackState.isPlaying;

    if (isPlaying && !_waveformController.isAnimating) {
      _waveformController.repeat();
    } else if (!isPlaying && _waveformController.isAnimating) {
      _waveformController.stop();
    }

    final currentPositionMs = playbackState.position.inMilliseconds;
    final totalDurationMs = playbackState.duration.inMilliseconds > 0
        ? playbackState.duration.inMilliseconds
        : (currentTrack?.durationMs ?? 180000);

    final progressRatio = totalDurationMs > 0
        ? (currentPositionMs / totalDurationMs).clamp(0.0, 1.0)
        : 0.0;

    final formattedElapsed = Formatters.formatDuration(playbackState.position);
    final formattedTotal = Formatters.formatDuration(
      playbackState.duration > Duration.zero
          ? playbackState.duration
          : Duration(milliseconds: totalDurationMs),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Physical Walkman Chassis
        Center(
          child: Container(
            width: widget.compact ? 270 : 300,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E2DC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD0CCC4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Screen Bezel (CRT Display)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onOpenNowPlaying != null) {
                        widget.onOpenNowPlaying!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
                        );
                      }
                    },
                    child: Container(
                      height: widget.compact ? 130 : 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2E3236), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // CRT Scanlines
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ScanlinesPainter(),
                            ),
                          ),

                          // Top status bar (LED indicator, text, battery)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isPlaying ? 'PLAY' : 'STANDBY',
                                      style: const TextStyle(
                                        color: Color(0xFF81C784),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Glowing red LED
                                    Container(
                                      width: 6.5,
                                      height: 6.5,
                                      decoration: BoxDecoration(
                                        color: isPlaying ? const Color(0xFFFF2A2A) : const Color(0xFF5A1414),
                                        shape: BoxShape.circle,
                                        boxShadow: isPlaying
                                            ? [
                                                const BoxShadow(
                                                  color: Color(0xFFFF2A2A),
                                                  blurRadius: 6,
                                                  spreadRadius: 1.5,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                // Retro Battery Icon
                                _buildBatteryIcon(),
                              ],
                            ),
                          ),

                          // Live Oscillating Waveform
                          Positioned.fill(
                            top: 26,
                            bottom: 8,
                            left: 12,
                            right: 12,
                            child: AnimatedBuilder(
                              animation: _waveformController,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _WaveformPainter(
                                    baseWaveform: _baseWaveform,
                                    animValue: _waveformController.value,
                                    isPlaying: isPlaying,
                                    progress: progressRatio,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Perforated Acoustic Speaker Grille
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: SizedBox(
                    height: 24,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SpeakerGrillePainter(),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Tactile Mechanical Button Console
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Container(
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6D2CA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBCB7AE), width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Button: Record / Favorite Red Dot
                        Expanded(
                          flex: 3,
                          child: _buildMechanicalButton(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                            color: const Color(0xFFECE9E2),
                            onTap: () {
                              _triggerHapticAndSound(MechanicalSoundType.pauseClick);
                              if (currentTrack != null) {
                                ref.read(playbackNotifierProvider.notifier).toggleFavorite(currentTrack);
                              }
                            },
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: (currentTrack?.isFavorite ?? false)
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFE53935).withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const VerticalDivider(color: Color(0xFFBCB7AE), width: 1.5, thickness: 1.5),

                        // Center Button: Bold Vibrant Orange-Red PLAY / PAUSE
                        Expanded(
                          flex: 4,
                          child: _buildMechanicalButton(
                            color: const Color(0xFFF14836),
                            onTap: () {
                              _triggerHapticAndSound(
                                isPlaying ? MechanicalSoundType.pauseClick : MechanicalSoundType.playClack,
                              );
                              ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                            },
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const VerticalDivider(color: Color(0xFFBCB7AE), width: 1.5, thickness: 1.5),

                        // Right Button Cluster (Rewind, Fast Forward, Pause)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              // Top split: Rewind & Fast Forward
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildMechanicalButton(
                                        color: const Color(0xFFDEDBD4),
                                        onTap: () {
                                          _triggerHapticAndSound(MechanicalSoundType.skipClick);
                                          ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                                        },
                                        child: const Icon(Icons.fast_rewind_rounded, size: 18, color: Color(0xFF333333)),
                                      ),
                                    ),
                                    const VerticalDivider(color: Color(0xFFBCB7AE), width: 1.5, thickness: 1.5),
                                    Expanded(
                                      child: _buildMechanicalButton(
                                        borderRadius: const BorderRadius.only(topRight: Radius.circular(13)),
                                        color: const Color(0xFFDEDBD4),
                                        onTap: () {
                                          _triggerHapticAndSound(MechanicalSoundType.skipClick);
                                          ref.read(playbackNotifierProvider.notifier).skipToNext();
                                        },
                                        child: const Icon(Icons.fast_forward_rounded, size: 18, color: Color(0xFF333333)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Color(0xFFBCB7AE), height: 1.5, thickness: 1.5),
                              // Bottom split: Pause Bar
                              Expanded(
                                child: _buildMechanicalButton(
                                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(13)),
                                  color: const Color(0xFFD8D4CC),
                                  onTap: () {
                                    _triggerHapticAndSound(MechanicalSoundType.pauseClick);
                                    ref.read(playbackNotifierProvider.notifier).pause();
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: 3.5, height: 12, color: const Color(0xFF444444)),
                                      const SizedBox(width: 4),
                                      Container(width: 3.5, height: 12, color: const Color(0xFF444444)),
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

                // Bottom Edge Ports and Red Slide Switch
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dual 3.5mm Recessed Jack Ports
                      Row(
                        children: [
                          _buildRecessedPort(),
                          const SizedBox(width: 6),
                          _buildRecessedPort(),
                        ],
                      ),

                      // Red Slide Switch
                      Container(
                        width: 34,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2022),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF5A5D60), width: 0.8),
                        ),
                        child: Align(
                          alignment: isPlaying ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 14,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEE3B30),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
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

        const SizedBox(height: 12),

        // Digital Time Display & Progress Line (matches 00:24 / 03:18 below widget)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$formattedElapsed / $formattedTotal',
                style: AppTypography.monoSmall.copyWith(
                  color: const Color(0xFF8A9096),
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              // Thin Coral Underline
              Container(
                width: 38,
                height: 2,
                decoration: BoxDecoration(
                  color: settings.accentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMechanicalButton({
    required Widget child,
    required VoidCallback onTap,
    Color color = const Color(0xFFEDEAE3),
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildRecessedPort() {
    return Container(
      width: 22,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D1F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF55575A), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 10,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 1.0),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Expanded(child: Container(color: Colors.white70)),
              const SizedBox(width: 1),
              Expanded(child: Container(color: Colors.white70)),
              const SizedBox(width: 1),
              Expanded(child: Container(color: Colors.white70)),
            ],
          ),
        ),
        Container(
          width: 1.5,
          height: 4,
          color: Colors.white70,
        ),
      ],
    );
  }
}

// ───────────────────────── Custom Painters ─────────────────────────

/// Draws authentic horizontal scanlines across CRT screen
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 3.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws live audio waveform bars with a distinct red playback cursor bar
class _WaveformPainter extends CustomPainter {
  final List<double> baseWaveform;
  final double animValue;
  final bool isPlaying;
  final double progress;

  _WaveformPainter({
    required this.baseWaveform,
    required this.animValue,
    required this.isPlaying,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = baseWaveform.length;
    final barWidth = (size.width / (count * 1.8)).clamp(1.5, 4.0);
    final spacing = (size.width - (barWidth * count)) / (count - 1);
    final centerY = size.height * 0.52;

    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final redPaint = Paint()
      ..color = const Color(0xFFFF3823)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth + 0.6;

    final activeIndex = (progress * (count - 1)).round().clamp(0, count - 1);

    for (int i = 0; i < count; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;
      double factor = baseWaveform[i];

      if (isPlaying) {
        final osc = math.sin((animValue * 2 * math.pi) + (i * 0.45));
        factor = (factor * (0.65 + 0.35 * osc)).clamp(0.08, 1.0);
      }

      final halfH = factor * (size.height * 0.40);
      final isRedCursor = i == activeIndex;

      canvas.drawLine(
        Offset(x, centerY - halfH),
        Offset(x, centerY + halfH),
        isRedCursor ? redPaint : whitePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.progress != progress;
  }
}

/// Realistic multi-hole acoustic speaker grille debossed into plastic
class _SpeakerGrillePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int rows = 4;
    const int cols = 38;

    final holeDarkPaint = Paint()
      ..color = const Color(0xFF4A4742)
      ..style = PaintingStyle.fill;

    final holeLightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final stepX = size.width / (cols + 1);
    final stepY = size.height / (rows + 1);

    for (int r = 1; r <= rows; r++) {
      final y = r * stepY;
      for (int c = 1; c <= cols; c++) {
        final x = c * stepX;
        // Shadow (deboss hole)
        canvas.drawCircle(Offset(x, y), 1.25, holeDarkPaint);
        // Highlight rim on bottom
        canvas.drawCircle(Offset(x, y + 0.6), 0.7, holeLightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
