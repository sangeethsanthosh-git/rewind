import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/features/audio_player/domain/playback_state.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/library/presentation/providers/library_provider.dart';
import 'package:spool/features/settings/domain/app_settings.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

/// Interactive Realistic Walkman Player with 3D Hinged Door, Dual Spindles,
/// Sliding Cassette, Right Tactile Metallic Keys, Vintage LCD Tape Counter,
/// and Deep Customization.
class WalkmanPlayerScreen extends ConsumerStatefulWidget {
  const WalkmanPlayerScreen({super.key});

  @override
  ConsumerState<WalkmanPlayerScreen> createState() => _WalkmanPlayerScreenState();
}

class _WalkmanPlayerScreenState extends ConsumerState<WalkmanPlayerScreen>
    with TickerProviderStateMixin {
  // Step State:
  // 0: Lid Closed, Cassette Out
  // 1: Lid Open, Cassette Out
  // 2: Lid Open, Cassette In
  // 3: Lid Closed, Cassette In (Playback Ready / Active)
  int _step = 3; // Default to loaded & ready if song is active, otherwise 0

  late final AnimationController _lidAnimController;
  late final Animation<double> _lidAnimation;

  late final AnimationController _cassetteAnimController;
  late final Animation<double> _cassetteProgress;

  late final AnimationController _reelSpinController;

  double _volumeLevel = 0.75;

  @override
  void initState() {
    super.initState();

    final playbackState = ref.read(playbackNotifierProvider);
    // If track is playing or loaded, start at state 3 (loaded & ready)
    if (playbackState.currentTrack != null) {
      _step = 3;
    } else {
      _step = 0;
    }

    // Lid Door Hinge Animation: 0.0 (closed) to -168 deg (-2.932 rad) (open)
    _lidAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _lidAnimation = Tween<double>(
      begin: 0.0,
      end: -168.0 * (math.pi / 180.0),
    ).animate(CurvedAnimation(
      parent: _lidAnimController,
      curve: const Cubic(0.45, 0.0, 0.2, 1.1),
    ));

    // Cassette Slide & Rotate Animation: 0.0 (ejected) to 1.0 (inserted & 90 deg)
    _cassetteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _cassetteProgress = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _cassetteAnimController,
      curve: const Cubic(0.5, 0.0, 0.2, 1.08),
    ));

    // Continuous Reel Spool Rotation Animation
    _reelSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (_step >= 2) {
      _cassetteAnimController.value = 1.0;
    }
    if (_step == 1 || _step == 2) {
      _lidAnimController.value = 1.0;
    }

    if (playbackState.isPlaying) {
      _reelSpinController.repeat();
    }
  }

  @override
  void dispose() {
    _lidAnimController.dispose();
    _cassetteAnimController.dispose();
    _reelSpinController.dispose();
    super.dispose();
  }

  void _syncReelAnimation(bool isPlaying) {
    if (isPlaying) {
      if (!_reelSpinController.isAnimating) {
        _reelSpinController.repeat();
      }
    } else {
      if (_reelSpinController.isAnimating) {
        _reelSpinController.stop();
      }
    }
  }

  Future<void> _transitionToStep(int targetStep) async {
    final prev = _step;
    final settings = ref.read(settingsNotifierProvider);

    if (targetStep != 3) {
      ref.read(playbackNotifierProvider.notifier).pause();
    }

    setState(() => _step = targetStep);

    // Sound and animation sequences matching the mechanical prototype
    if (targetStep == 1 && prev == 0) {
      // Open lid from closed
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
      await _lidAnimController.forward();
    } else if (targetStep == 0 && prev == 1) {
      // Close lid with cassette out
      await _lidAnimController.reverse();
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
    } else if (targetStep == 2 && prev == 1) {
      // Slide cassette in while lid is open
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.cassetteInsert,
        settings: settings,
      );
      await _cassetteAnimController.forward();
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
    } else if (targetStep == 1 && prev == 2) {
      // Eject cassette out
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.cassetteEject,
        settings: settings,
      );
      await _cassetteAnimController.reverse();
    } else if (targetStep == 3 && prev == 2) {
      // Close lid with cassette in
      await _lidAnimController.reverse();
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
    } else if (targetStep == 2 && prev == 3) {
      // Open lid with cassette in
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
      await _lidAnimController.forward();
    }
  }

  WalkmanThemeData _resolveWalkmanTheme(AppSettings settings) {
    switch (settings.walkmanChassisTheme) {
      case 'stealthBlack':
        return const WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E3036), Color(0xFF1E2024), Color(0xFF121316)],
          ),
          lidFrontColor: Color(0xFF26282E),
          lidBackGradient: LinearGradient(
            colors: [Color(0xFF1A1B20), Color(0xFF262830)],
          ),
          brandingColor: Color(0xFFE2E4EB),
          stripGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF6E727A), Color(0xFF8E939D), Color(0xFF686C74)],
          ),
          keyCapGradient: LinearGradient(
            colors: [Color(0xFF454850), Color(0xFF222428)],
          ),
        );
      case 'solarYellow':
        return const WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7CA45), Color(0xFFE5B025), Color(0xFFD49A15)],
          ),
          lidFrontColor: Color(0xFFE5B025),
          lidBackGradient: LinearGradient(
            colors: [Color(0xFFD49A15), Color(0xFFC48A0E)],
          ),
          brandingColor: Color(0xFF1C1D22),
          stripGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB9BDC4), Color(0xFFEEF0F3), Color(0xFFB3B7BE)],
          ),
          keyCapGradient: LinearGradient(
            colors: [Color(0xFF5A5D64), Color(0xFF2B2E34)],
          ),
        );
      case 'vintageSilver':
        return const WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDCDFE5), Color(0xFFC4C8D2), Color(0xFFA8ABB4)],
          ),
          lidFrontColor: Color(0xFFBFC3CD),
          lidBackGradient: LinearGradient(
            colors: [Color(0xFFA8ABB4), Color(0xFFB8BCC6)],
          ),
          brandingColor: Color(0xFF22242B),
          stripGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFAEB2B9), Color(0xFFD8DCE3), Color(0xFFA8ACB3)],
          ),
          keyCapGradient: LinearGradient(
            colors: [Color(0xFF50535A), Color(0xFF282A30)],
          ),
        );
      case 'tokyoBurgundy':
        return const WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B233D), Color(0xFF4E162B), Color(0xFF350E1D)],
          ),
          lidFrontColor: Color(0xFF53192F),
          lidBackGradient: LinearGradient(
            colors: [Color(0xFF350E1D), Color(0xFF481428)],
          ),
          brandingColor: Color(0xFFF8DCE5),
          stripGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB9BDC4), Color(0xFFEEF0F3), Color(0xFFB3B7BE)],
          ),
          keyCapGradient: LinearGradient(
            colors: [Color(0xFF60646C), Color(0xFF2B2E34)],
          ),
        );
      case 'customAccent':
        final c = settings.accentColor;
        final cDark = Color.lerp(c, Colors.black, 0.45) ?? c;
        final cDarker = Color.lerp(c, Colors.black, 0.70) ?? c;
        return WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c, cDark, cDarker],
          ),
          lidFrontColor: cDark,
          lidBackGradient: LinearGradient(
            colors: [cDarker, cDark],
          ),
          brandingColor: Colors.white,
          stripGradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB9BDC4), Color(0xFFEEF0F3), Color(0xFFB3B7BE)],
          ),
          keyCapGradient: const LinearGradient(
            colors: [Color(0xFF60646C), Color(0xFF2B2E34)],
          ),
        );
      case 'classicBlue':
      default:
        // Iconic Sony TPS-L2 Metallic Blue
        return const WalkmanThemeData(
          bodyGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A7FB8), Color(0xFF2F5F94), Color(0xFF284E80)],
          ),
          lidFrontColor: Color(0xFF3868A0),
          lidBackGradient: LinearGradient(
            colors: [Color(0xFF2A5381), Color(0xFF356399)],
          ),
          brandingColor: Color(0xFFDCE6F2),
          stripGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFB9BDC4), Color(0xFFEEF0F3), Color(0xFFB3B7BE)],
          ),
          keyCapGradient: LinearGradient(
            colors: [Color(0xFF60646C), Color(0xFF2B2E34)],
          ),
        );
    }
  }

  void _openCustomizerModal(BuildContext context) {
    final notifier = ref.read(settingsNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16171B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final curSettings = ref.watch(settingsNotifierProvider);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WALKMAN CUSTOMIZER',
                          style: AppTypography.displaySmall.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chassis Color / Finish
                    Text('CHASSIS FINISH', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildThemeOptionChip(
                          label: 'Classic TPS-L2',
                          code: 'classicBlue',
                          swatch: const Color(0xFF3868A0),
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('classicBlue'),
                        ),
                        _buildThemeOptionChip(
                          label: 'Stealth Black',
                          code: 'stealthBlack',
                          swatch: const Color(0xFF26282E),
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('stealthBlack'),
                        ),
                        _buildThemeOptionChip(
                          label: 'Solar Yellow',
                          code: 'solarYellow',
                          swatch: const Color(0xFFF7CA45),
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('solarYellow'),
                        ),
                        _buildThemeOptionChip(
                          label: 'Vintage Silver',
                          code: 'vintageSilver',
                          swatch: const Color(0xFFC4C8D2),
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('vintageSilver'),
                        ),
                        _buildThemeOptionChip(
                          label: 'Tokyo Burgundy',
                          code: 'tokyoBurgundy',
                          swatch: const Color(0xFF6B233D),
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('tokyoBurgundy'),
                        ),
                        _buildThemeOptionChip(
                          label: 'Cyber Accent',
                          code: 'customAccent',
                          swatch: curSettings.accentColor,
                          current: curSettings.walkmanChassisTheme,
                          onSelect: () => notifier.setWalkmanChassisTheme('customAccent'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Branding Text Customization
                    Text('WALKMAN BRANDING', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final preset in ['SONY', 'REWIND', 'TPS-L2'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(preset, style: AppTypography.monoSmall),
                              selected: curSettings.walkmanBrandingText.toUpperCase() == preset,
                              selectedColor: curSettings.accentColor.withAlpha(80),
                              onSelected: (_) => notifier.setWalkmanBrandingText(preset),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Hotline Tab Color
                    Text('HOTLINE TAB COLOR', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final color in [
                          const Color(0xFFF08A1C), // Classic Hotline Orange
                          const Color(0xFFFF3B30), // Red
                          const Color(0xFF00C7BE), // Cyan
                          const Color(0xFFFFD60A), // Gold
                          curSettings.accentColor, // Universal Accent
                        ])
                          GestureDetector(
                            onTap: () {
                              notifier.setWalkmanHotlineColor(color);
                              MechanicalSoundService.instance.playMechanicalSound(
                                MechanicalSoundType.skipClick,
                                settings: curSettings,
                              );
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: curSettings.walkmanHotlineColorValue == color.toARGB32()
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Mechanical Sounds & Motor Ambience
                    Text('TACTILE AUDIO & HAPTICS', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: curSettings.accentColor,
                      title: Text('Mechanical Button Clicks', style: AppTypography.bodyMedium),
                      subtitle: Text('Hardware click on every tactile button', style: AppTypography.bodySmall),
                      value: curSettings.enableMechanicalSounds,
                      onChanged: (val) {
                        notifier.setMechanicalSounds(val);
                        if (val) {
                          MechanicalSoundService.instance.playMechanicalSound(
                            MechanicalSoundType.playClack,
                            settings: curSettings.copyWith(enableMechanicalSounds: true),
                          );
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: curSettings.accentColor,
                      title: Text('DC Capstan Motor Hum', style: AppTypography.bodyMedium),
                      subtitle: Text('Faint analog transport motor ambience during playback', style: AppTypography.bodySmall),
                      value: curSettings.enableMotorAmbience,
                      onChanged: (val) => notifier.setMotorAmbience(val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: curSettings.accentColor,
                      title: Text('Tactile Haptic Feedback', style: AppTypography.bodyMedium),
                      subtitle: Text('Vibrate upon depressing mechanical keys', style: AppTypography.bodySmall),
                      value: curSettings.enableHaptics,
                      onChanged: (val) => notifier.setHaptics(val),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionChip({
    required String label,
    required String code,
    required Color swatch,
    required String current,
    required VoidCallback onSelect,
  }) {
    final isSelected = current == code;
    return InkWell(
      onTap: () {
        onSelect();
        MechanicalSoundService.instance.playMechanicalSound(
          MechanicalSoundType.skipClick,
          settings: ref.read(settingsNotifierProvider),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E313A) : const Color(0xFF1E2026),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white70 : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.monoSmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final libraryState = ref.watch(libraryNotifierProvider);
    final theme = _resolveWalkmanTheme(settings);
    final track = playbackState.currentTrack;

    _syncReelAnimation(playbackState.isPlaying);

    // Update motor ambience on state change
    MechanicalSoundService.instance.updateMotorAmbience(
      isPlayingMusic: playbackState.isPlaying,
      settings: settings,
    );

    // Calculate tape progress for tape spools
    final durationMs = playbackState.duration.inMilliseconds;
    final positionMs = playbackState.position.inMilliseconds;
    final double progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    // Left and right tape pack diameters (in px)
    final double leftRadius = 22.0 - (10.0 * progress);
    final double rightRadius = 12.0 + (10.0 * progress);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1013),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Tool Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    tooltip: 'Back',
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.pauseClick,
                        settings: settings,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  Text(
                    'PORTABLE STEREO CASSETTE PLAYER',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: settings.accentColor),
                    tooltip: 'Walkman Customizer',
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      _openCustomizerModal(context);
                    },
                  ),
                ],
              ),
            ),

            // Walkman Realistic Stage Container (Scales gracefully via FittedBox)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 360,
                    height: 520,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main Walkman Chassis Body
                        Positioned(
                          left: 15,
                          top: 10,
                          width: 330,
                          height: 480,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: theme.bodyGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99000000),
                                  blurRadius: 36,
                                  offset: Offset(0, 20),
                                ),
                                BoxShadow(
                                  color: Color(0x33FFFFFF),
                                  blurRadius: 1,
                                  offset: Offset(0, 1),
                                  blurStyle: BlurStyle.inner,
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Top Hotline Tab
                                Positioned(
                                  top: -7,
                                  left: 195,
                                  child: Container(
                                    width: 36,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: settings.walkmanHotlineColor,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Top Branding Name (SONY / REWIND)
                                Positioned(
                                  top: 24,
                                  left: 20,
                                  width: 220,
                                  child: Text(
                                    settings.walkmanBrandingText.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.5,
                                      color: theme.brandingColor,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Recessed Cassette Bay (Deep Interior Chamber)
                                Positioned(
                                  left: 20,
                                  top: 65,
                                  width: 220,
                                  height: 380,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF101216),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black,
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: Offset(0, 4),
                                          blurStyle: BlurStyle.inner,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Spindle 1 (Upper Reel Spindle)
                                        Positioned(
                                          left: 102,
                                          top: 110,
                                          child: _buildBaySpindle(),
                                        ),
                                        // Spindle 2 (Lower Reel Spindle)
                                        Positioned(
                                          left: 102,
                                          top: 240,
                                          child: _buildBaySpindle(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Animated Cassette Tape (Slides into the bay and rotates 90 deg)
                                AnimatedBuilder(
                                  animation: _cassetteAnimController,
                                  builder: (context, child) {
                                    final t = _cassetteProgress.value;
                                    // Interpolate translation & rotation:
                                    // t=0 (ejected): x=0, y=270, rotation=0 deg
                                    // t=1 (inserted): x=-10, y=105, rotation=90 deg
                                    final currentY = 105.0 + (165.0 * (1.0 - t));
                                    final currentX = -10.0 + (10.0 * (1.0 - t));
                                    final currentAngle = (math.pi / 2) * t;

                                    return Positioned(
                                      left: 20 + currentX,
                                      top: currentY,
                                      width: 240,
                                      height: 150,
                                      child: Transform.rotate(
                                        angle: currentAngle,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_step == 1) {
                                              _transitionToStep(2);
                                            } else if (_step == 2) {
                                              _transitionToStep(1);
                                            }
                                          },
                                          child: _buildRealisticCassette(
                                            track: track,
                                            isPlaying: playbackState.isPlaying,
                                            leftRadius: leftRadius,
                                            rightRadius: rightRadius,
                                            rotationAngle: _reelSpinController.value * 2 * math.pi,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // 3D Hinged Lid with Clear Window & "WALKMAN" Lettering
                                Positioned(
                                  left: 20,
                                  top: 65,
                                  width: 220,
                                  height: 380,
                                  child: AnimatedBuilder(
                                    animation: _lidAnimController,
                                    builder: (context, child) {
                                      final angle = _lidAnimation.value;
                                      final isFrontFacing = angle.abs() < (math.pi / 2);

                                      return Transform(
                                        alignment: Alignment.centerLeft,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.0012)
                                          ..rotateY(angle),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_step == 0) {
                                              _transitionToStep(1);
                                            } else if (_step == 1) {
                                              _transitionToStep(0);
                                            } else if (_step == 2) {
                                              _transitionToStep(3);
                                            } else if (_step == 3) {
                                              _transitionToStep(2);
                                            }
                                          },
                                          child: isFrontFacing
                                              ? _buildLidFront(theme)
                                              : _buildLidBack(theme),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Right Brushed Metallic Tactile Key Strip
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  width: 58,
                                  height: 480,
                                  child: _buildRightTactileKeyStrip(
                                    theme: theme,
                                    settings: settings,
                                    isPlaying: playbackState.isPlaying,
                                    onOpen: () {
                                      if (_step == 0) {
                                        _transitionToStep(1);
                                      } else if (_step == 3) {
                                        _transitionToStep(2);
                                      }
                                    },
                                    onPlay: () {
                                      if (_step == 3) {
                                        if (playbackState.isPlaying) {
                                          ref.read(playbackNotifierProvider.notifier).pause();
                                        } else {
                                          if (track == null && libraryState.allSongs.isNotEmpty) {
                                            ref.read(playbackNotifierProvider.notifier).playTrack(
                                              libraryState.allSongs.first,
                                              queue: libraryState.allSongs,
                                            );
                                          } else {
                                            ref.read(playbackNotifierProvider.notifier).resume();
                                          }
                                        }
                                      }
                                    },
                                    onStop: () {
                                      if (_step == 3 && playbackState.isPlaying) {
                                        ref.read(playbackNotifierProvider.notifier).pause();
                                      } else if (_step > 0) {
                                        _transitionToStep(_step - 1);
                                      }
                                    },
                                    onRewind: () {
                                      if (_step == 3) {
                                        final cur = playbackState.position;
                                        final target = cur - const Duration(seconds: 10);
                                        ref.read(playbackNotifierProvider.notifier).seek(
                                          target > Duration.zero ? target : Duration.zero,
                                        );
                                      }
                                    },
                                    onFastForward: () {
                                      if (_step == 3) {
                                        final cur = playbackState.position;
                                        final dur = playbackState.duration;
                                        final target = cur + const Duration(seconds: 10);
                                        ref.read(playbackNotifierProvider.notifier).seek(
                                          target < dur ? target : dur,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Lower Digital Control Panel (Vintage LCD, Status, Step Buttons, Volume)
            _buildLowerControlPanel(
              settings: settings,
              playbackState: playbackState,
              trackTitle: track?.title,
              onGoNext: () {
                if (_step < 3) {
                  _transitionToStep(_step + 1);
                } else {
                  // Toggle Play/Stop
                  final isPlaying = playbackState.isPlaying;
                  MechanicalSoundService.instance.playMechanicalSound(
                    isPlaying ? MechanicalSoundType.pauseClick : MechanicalSoundType.playClack,
                    settings: settings,
                  );
                  if (isPlaying) {
                    ref.read(playbackNotifierProvider.notifier).pause();
                  } else {
                    if (track == null && libraryState.allSongs.isNotEmpty) {
                      ref.read(playbackNotifierProvider.notifier).playTrack(
                        libraryState.allSongs.first,
                        queue: libraryState.allSongs,
                      );
                    } else {
                      ref.read(playbackNotifierProvider.notifier).resume();
                    }
                  }
                }
              },
              onBack: () {
                if (_step == 3 && playbackState.isPlaying) {
                  MechanicalSoundService.instance.playMechanicalSound(
                    MechanicalSoundType.pauseClick,
                    settings: settings,
                  );
                  ref.read(playbackNotifierProvider.notifier).pause();
                } else if (_step > 0) {
                  _transitionToStep(_step - 1);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildBaySpindle() {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFF2F4F7), Color(0xFF8D929C)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF101216),
          ),
        ),
      ),
    );
  }

  Widget _buildLidFront(WalkmanThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.lidFrontColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Clear Acrylic Inspection Window (.win)
          Positioned(
            left: 14,
            top: 20,
            right: 14,
            bottom: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withAlpha(90), width: 1.8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x28FFFFFF),
                    Color(0x05FFFFFF),
                    Color(0x18FFFFFF),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Italic Bold "WALKMAN" Lettering at bottom of lid
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Text(
              'WALKMAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2.0,
                color: Colors.white.withAlpha(240),
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLidBack(WalkmanThemeData theme) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.lidBackGradient,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black38, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 170,
            height: 310,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Icon(
                Icons.album_outlined,
                color: Colors.white12,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealisticCassette({
    required dynamic track,
    required bool isPlaying,
    required double leftRadius,
    required double rightRadius,
    required double rotationAngle,
  }) {
    final title = track?.title ?? 'Rewind Hi-Fi Demo';
    final artist = track?.artist ?? 'Analog Sound System';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C20),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 4 Screws in corners
          _buildScrew(left: 6, top: 6),
          _buildScrew(right: 6, top: 6),
          _buildScrew(left: 6, bottom: 6),
          _buildScrew(right: 6, bottom: 6),

          // Vintage Paper Label
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            height: 102,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1E5A6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Vintage Decorative Corner Arcs
                  Positioned(
                    left: -20,
                    top: -22,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFF3D96A), Color(0xFF7AA6DC)],
                          stops: [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -18,
                    top: -18,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFE9822C), Color(0xFFF4B934)],
                          stops: [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Script Song Title
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 4,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2F5A),
                      ),
                    ),
                  ),

                  // Badges: "Side A", "REWIND Hi-Fi"
                  Positioned(
                    left: 6,
                    top: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'SIDE A',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2F5A),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        artist.length > 12 ? artist.substring(0, 12) : artist,
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2F5A),
                        ),
                      ),
                    ),
                  ),

                  // Clear Inspection Pill Window
                  Positioned(
                    left: 33,
                    top: 46,
                    width: 150,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14151A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left Tape Pack
                          Positioned(
                            left: 26 - leftRadius,
                            child: Container(
                              width: leftRadius * 2,
                              height: leftRadius * 2,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0xFF24170E), Color(0xFF4D3727)],
                                ),
                              ),
                            ),
                          ),

                          // Right Tape Pack
                          Positioned(
                            left: 124 - rightRadius,
                            child: Container(
                              width: rightRadius * 2,
                              height: rightRadius * 2,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0xFF24170E), Color(0xFF4D3727)],
                                ),
                              ),
                            ),
                          ),

                          // Left Spool Hub (Rotates during play)
                          Positioned(
                            left: 9,
                            child: Transform.rotate(
                              angle: rotationAngle,
                              child: _buildSpoolHub(),
                            ),
                          ),

                          // Right Spool Hub (Rotates during play)
                          Positioned(
                            left: 107,
                            child: Transform.rotate(
                              angle: rotationAngle,
                              child: _buildSpoolHub(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Head Cavity Trapezoid Foot
          Positioned(
            left: 45,
            right: 45,
            bottom: 0,
            height: 32,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2B2D34),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0B0C0F),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0B0C0F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrew({double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF4A4C54),
        ),
      ),
    );
  }

  Widget _buildSpoolHub() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFE3E6EC),
            Color(0xFF8E939E),
            Color(0xFFE3E6EC),
            Color(0xFF8E939E),
            Color(0xFFE3E6EC),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF14151A),
          ),
        ),
      ),
    );
  }

  Widget _buildRightTactileKeyStrip({
    required WalkmanThemeData theme,
    required AppSettings settings,
    required bool isPlaying,
    required VoidCallback onOpen,
    required VoidCallback onPlay,
    required VoidCallback onStop,
    required VoidCallback onRewind,
    required VoidCallback onFastForward,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.stripGradient,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: const Border(
          left: BorderSide(color: Color(0x40000000), width: 1.2),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          _buildTactileKey(
            label: 'OPEN',
            theme: theme,
            settings: settings,
            soundType: MechanicalSoundType.doorLatch,
            onPressed: onOpen,
          ),
          const SizedBox(height: 10),
          _buildTactileKey(
            label: 'PLAY',
            isDepressed: isPlaying && _step == 3,
            theme: theme,
            settings: settings,
            soundType: MechanicalSoundType.playClack,
            onPressed: onPlay,
          ),
          const SizedBox(height: 10),
          _buildTactileKey(
            label: 'STOP',
            theme: theme,
            settings: settings,
            soundType: MechanicalSoundType.pauseClick,
            onPressed: onStop,
          ),
          const SizedBox(height: 10),
          _buildTactileKey(
            label: 'REW',
            theme: theme,
            settings: settings,
            soundType: MechanicalSoundType.skipClick,
            onPressed: onRewind,
          ),
          const SizedBox(height: 10),
          _buildTactileKey(
            label: 'FF',
            theme: theme,
            settings: settings,
            soundType: MechanicalSoundType.skipClick,
            onPressed: onFastForward,
          ),
          const Spacer(),
          // 3.5mm Headphone Jack
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2C32),
              border: Border.all(color: const Color(0xFF70737C), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, blurRadius: 3, blurStyle: BlurStyle.inner),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTactileKey({
    required String label,
    required WalkmanThemeData theme,
    required AppSettings settings,
    required MechanicalSoundType soundType,
    required VoidCallback onPressed,
    bool isDepressed = false,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        MechanicalSoundService.instance.playMechanicalSound(
          soundType,
          settings: settings,
        );
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 32,
        height: 52,
        transform: Matrix4.translationValues(0, isDepressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          gradient: isDepressed
              ? const LinearGradient(
                  colors: [Color(0xFF2B2E34), Color(0xFF454950)],
                )
              : theme.keyCapGradient,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDepressed ? Colors.black : Colors.white24,
            width: 0.8,
          ),
          boxShadow: isDepressed
              ? const [
                  BoxShadow(color: Colors.black54, blurRadius: 2, blurStyle: BlurStyle.inner),
                ]
              : const [
                  BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2)),
                ],
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: Color(0xFFECEEF2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLowerControlPanel({
    required AppSettings settings,
    required SpoolPlaybackState playbackState,
    required String? trackTitle,
    required VoidCallback onGoNext,
    required VoidCallback onBack,
  }) {
    // Determine dynamic status message and primary action button label
    String statusMsg = '';
    String actionLabel = '';

    switch (_step) {
      case 0:
        statusMsg = 'The lid is closed. Open it to load a tape.';
        actionLabel = 'Open the Walkman';
        break;
      case 1:
        statusMsg = 'The lid is open. Drag the cassette up into the bay, or tap it.';
        actionLabel = 'Insert the cassette';
        break;
      case 2:
        statusMsg = 'Tape loaded. Close the lid.';
        actionLabel = 'Close the lid';
        break;
      case 3:
      default:
        if (playbackState.isPlaying) {
          statusMsg = 'Now playing: ${trackTitle ?? "Side A"}.';
          actionLabel = 'Stop';
        } else {
          statusMsg = 'Ready to play.';
          actionLabel = 'Press play';
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vintage Backlit Olive-Green LCD Tape Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB9C9A0),
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Text(
              Formatters.formatDuration(playbackState.position),
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.5,
                color: Color(0xFF2B3320),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Dynamic Status Narrative Text
          Text(
            statusMsg,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          // Action Buttons: "Back" & Primary Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _step > 0 ? onBack : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onGoNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Analog Volume Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Volume', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 10),
              SizedBox(
                width: 170,
                height: 24,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: settings.walkmanHotlineColor,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: settings.walkmanHotlineColor,
                  ),
                  child: Slider(
                    value: _volumeLevel,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() => _volumeLevel = val);
                      ref.read(audioPlayerServiceProvider).rawPlayer.setVolume(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Walkman Chassis Color Theme Definition
class WalkmanThemeData {
  final Gradient bodyGradient;
  final Color lidFrontColor;
  final Gradient lidBackGradient;
  final Color brandingColor;
  final Gradient stripGradient;
  final Gradient keyCapGradient;

  const WalkmanThemeData({
    required this.bodyGradient,
    required this.lidFrontColor,
    required this.lidBackGradient,
    required this.brandingColor,
    required this.stripGradient,
    required this.keyCapGradient,
  });
}
