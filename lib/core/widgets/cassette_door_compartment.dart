import 'package:flutter/material.dart';
import 'package:spool/core/constants/app_colors.dart';

import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/widgets/cassette_tape_widget.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/settings/domain/app_settings.dart';

class CassetteDoorCompartment extends StatefulWidget {
  final AudioTrack? track;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final AppSettings settings;
  final VoidCallback? onEjected;

  const CassetteDoorCompartment({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.settings,
    this.onEjected,
  });

  @override
  State<CassetteDoorCompartment> createState() => CassetteDoorCompartmentState();
}

class CassetteDoorCompartmentState extends State<CassetteDoorCompartment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _doorAnimController;
  late final Animation<double> _doorAngle;
  late final Animation<double> _cassetteSlide;
  bool _isEjected = false;
  String? _lastLoadedAlbumId;

  bool get isEjected => _isEjected;

  @override
  void initState() {
    super.initState();
    _doorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _doorAngle = Tween<double>(begin: 0.0, end: -0.32).animate(
      CurvedAnimation(
        parent: _doorAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _cassetteSlide = Tween<double>(begin: 0.0, end: -85.0).animate(
      CurvedAnimation(
        parent: _doorAnimController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _lastLoadedAlbumId = widget.track?.album;
  }

  @override
  void didUpdateWidget(covariant CassetteDoorCompartment oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If album changed and not reduced animation, trigger insertion sequence!
    final currentAlbum = widget.track?.album;
    if (currentAlbum != null && currentAlbum != _lastLoadedAlbumId) {
      _lastLoadedAlbumId = currentAlbum;
      if (!widget.settings.reducedAnimation) {
        animateInsertion();
      }
    }
  }

  Future<void> eject() async {
    if (_isEjected) return;
    setState(() => _isEjected = true);

    // Play eject spring audio & haptics
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.cassetteEject,
      settings: widget.settings,
    );

    if (widget.settings.reducedAnimation) {
      _doorAnimController.value = 1.0;
    } else {
      await _doorAnimController.forward();
    }
    widget.onEjected?.call();
  }

  Future<void> toggleEject() async {
    if (_isEjected) {
      await animateInsertion();
    } else {
      await eject();
    }
  }

  Future<void> animateInsertion() async {
    _doorAnimController.value = 1.0;
    setState(() => _isEjected = false);

    // Trigger plastic insertion sliding sound
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.cassetteInsert,
      settings: widget.settings,
    );

    if (widget.settings.reducedAnimation) {
      _doorAnimController.value = 0.0;
    } else {
      await _doorAnimController.reverse();
      // Door latch closing snap sound
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: widget.settings,
      );
    }
  }

  @override
  void dispose() {
    _doorAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _doorAnimController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (_isEjected) {
              animateInsertion();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141418), // Interior cassette well
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C35), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(220),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sliding Cassette inside the carriage
              Transform.translate(
                offset: Offset(0, _cassetteSlide.value),
                child: CassetteTapeWidget(
                  track: widget.track,
                  isPlaying: widget.isPlaying && !_isEjected,
                  position: widget.position,
                  duration: widget.duration,
                  labelColor: widget.track != null
                      ? AppColors.spinePalette[widget.track!.title.hashCode.abs() % AppColors.spinePalette.length]
                      : null,
                ),
              ),

              // Smoked Acrylic Cassette Door with 3D Perspective Tilt
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(_doorAngle.value),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8), // Smoked glass door
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Smoked window diagonal reflection sheen
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(30),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.white.withAlpha(15),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Walkman compartment branding on glass door
                      Positioned(
                        top: 12,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isPlaying && !_isEjected
                                    ? AppColors.tapeGreen
                                    : const Color(0xFF33333A),
                                boxShadow: widget.isPlaying && !_isEjected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.tapeGreen.withAlpha(180),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AUTO REVERSE • STEREO DECK',
                              style: AppTypography.monoSmall.copyWith(
                                color: Colors.white.withAlpha(160),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Eject latch handle indicator
                      Positioned(
                        bottom: 8,
                        right: 14,
                        child: Text(
                          _isEjected ? 'DOOR OPEN' : 'DOOR LOCKED',
                          style: AppTypography.monoSmall.copyWith(
                            color: _isEjected ? AppColors.tapeAmber : Colors.white.withAlpha(100),
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    );
  }
}
