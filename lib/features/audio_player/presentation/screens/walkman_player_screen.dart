import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/artwork_widget.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/audio_player/domain/playback_state.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/library/presentation/providers/library_provider.dart';
import 'package:spool/features/settings/domain/app_settings.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

/// Interactive Realistic Walkman Player with:
/// 1. 3D Hinged Lid with 100% Transparent Acrylic Glass Window
/// 2. Cassette Jewel Case Opening & Tape Slide Animation
/// 3. Cassette Tape displaying real Album Cover Image & Spinning Spools
/// 4. Right Tactile Metallic Mechanical Keys with Hardware SoundPool clicks
/// 5. Vintage LCD Tape Counter & Deep Walkman Customization
class WalkmanPlayerScreen extends ConsumerStatefulWidget {
  final bool isNavbarTab;
  final VoidCallback? onNavigateHome;

  const WalkmanPlayerScreen({
    super.key,
    this.isNavbarTab = false,
    this.onNavigateHome,
  });

  @override
  ConsumerState<WalkmanPlayerScreen> createState() => _WalkmanPlayerScreenState();
}

class _WalkmanPlayerScreenState extends ConsumerState<WalkmanPlayerScreen>
    with TickerProviderStateMixin {
  // Step State:
  // 0: Walkman closed, Cassette in closed Jewel Case below
  // 1: Walkman open, Cassette Case open, Cassette ready
  // 2: Walkman open, Cassette loaded in Bay (rotated 90 deg)
  // 3: Walkman closed, Cassette loaded & visible through transparent glass
  int _step = 3;
  int _selectedTrackIndex = 0;

  late final AnimationController _lidAnimController;
  late final Animation<double> _lidAnimation;

  late final AnimationController _caseLidAnimController;
  late final Animation<double> _caseLidAnimation;

  late final AnimationController _cassetteAnimController;
  late final Animation<double> _cassetteProgress;

  late final AnimationController _reelSpinController;

  double _volumeLevel = 0.75;

  @override
  void initState() {
    super.initState();

    final playbackState = ref.read(playbackNotifierProvider);
    final libraryState = ref.read(libraryNotifierProvider);
    final songs = playbackState.queue.isNotEmpty ? playbackState.queue : libraryState.allSongs;
    if (playbackState.currentTrack != null && songs.isNotEmpty) {
      final idx = songs.indexWhere((t) => t.id == playbackState.currentTrack!.id);
      if (idx >= 0) {
        _selectedTrackIndex = idx;
      }
      _step = 3;
    } else {
      _step = 0;
    }

    // Walkman Lid Door Hinge: 0.0 (closed) to -168 deg (open)
    _lidAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _lidAnimation = Tween<double>(
      begin: 0.0,
      end: -168.0 * (math.pi / 180.0),
    ).animate(CurvedAnimation(
      parent: _lidAnimController,
      curve: const Cubic(0.45, 0.0, 0.2, 1.1),
    ));

    // Cassette Jewel Case Hinge: 0.0 (closed) to -160 deg (open)
    _caseLidAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _caseLidAnimation = Tween<double>(
      begin: 0.0,
      end: -160.0 * (math.pi / 180.0),
    ).animate(CurvedAnimation(
      parent: _caseLidAnimController,
      curve: const Cubic(0.45, 0.0, 0.2, 1.1),
    ));

    // Cassette Slide & Rotate: 0.0 (in case) to 1.0 (in bay, rotated 90 deg)
    _cassetteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      _caseLidAnimController.value = 1.0;
    }
    if (_step == 1 || _step == 2) {
      _lidAnimController.value = 1.0;
      _caseLidAnimController.value = 1.0;
    }

    if (playbackState.isPlaying) {
      _reelSpinController.repeat();
    }
  }

  @override
  void dispose() {
    _lidAnimController.dispose();
    _caseLidAnimController.dispose();
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

  void _swapCassette(int delta) {
    final songs = ref.read(playbackNotifierProvider).queue.isNotEmpty
        ? ref.read(playbackNotifierProvider).queue
        : ref.read(libraryNotifierProvider).allSongs;
    if (songs.isEmpty) return;
    setState(() {
      _selectedTrackIndex = (_selectedTrackIndex + delta) % songs.length;
      if (_selectedTrackIndex < 0) _selectedTrackIndex += songs.length;
    });
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: ref.read(settingsNotifierProvider),
    );
  }

  Future<void> _ejectAndSwap() async {
    if (ref.read(playbackNotifierProvider).isPlaying) {
      ref.read(playbackNotifierProvider.notifier).pause();
    }
    if (_step == 3) {
      await _transitionToStep(2);
      await _transitionToStep(1);
    } else if (_step == 2) {
      await _transitionToStep(1);
    } else if (_step == 0) {
      await _transitionToStep(1);
    }
  }

  Future<void> _transitionToStep(int targetStep) async {
    final prev = _step;
    final settings = ref.read(settingsNotifierProvider);

    if (targetStep != 3) {
      ref.read(playbackNotifierProvider.notifier).pause();
    }

    setState(() => _step = targetStep);

    if (targetStep == 1 && prev == 0) {
      // Open Walkman lid AND open Cassette Case lid
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
      await Future.wait([
        _lidAnimController.forward(),
        _caseLidAnimController.forward(),
      ]);
    } else if (targetStep == 0 && prev == 1) {
      // Close Cassette Case lid AND Walkman lid
      await Future.wait([
        _caseLidAnimController.reverse(),
        _lidAnimController.reverse(),
      ]);
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
    } else if (targetStep == 2 && prev == 1) {
      // Slide cassette out of case and into Walkman bay
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
      // Eject cassette from Walkman bay back into case
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.cassetteEject,
        settings: settings,
      );
      await _cassetteAnimController.reverse();
    } else if (targetStep == 3 && prev == 2) {
      // Close Walkman lid over loaded cassette
      await _lidAnimController.reverse();
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.doorLatch,
        settings: settings,
      );
    } else if (targetStep == 2 && prev == 3) {
      // Open Walkman lid with cassette loaded
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

                    Text('CHASSIS FINISH & CUSTOM SKIN', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),

                    // Custom Skin Image Picker Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20222A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: curSettings.walkmanCustomSkinPath != null
                              ? curSettings.accentColor
                              : Colors.white12,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.brush_rounded, size: 18, color: curSettings.accentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Custom Image Skin',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: curSettings.accentColor,
                                  foregroundColor: curSettings.accentColor.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
                                label: Text(
                                  curSettings.walkmanCustomSkinPath != null ? 'CHANGE' : 'CHOOSE SKIN',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final files = await FilePicker.pickFiles(type: FileType.image);
                                  if (files.isNotEmpty && files.first.path != null) {
                                    notifier.setWalkmanCustomSkin(files.first.path);
                                  }
                                },
                              ),
                            ],
                          ),
                          if (curSettings.walkmanCustomSkinPath != null &&
                              File(curSettings.walkmanCustomSkinPath!).existsSync()) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(curSettings.walkmanCustomSkinPath!),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ACTIVE WALKMAN SKIN',
                                        style: TextStyle(
                                          color: curSettings.accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9.5,
                                          fontFamily: 'Courier',
                                        ),
                                      ),
                                      Text(
                                        curSettings.walkmanCustomSkinPath!.split(Platform.pathSeparator).last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.vinylRed, size: 20),
                                  tooltip: 'Remove Custom Skin',
                                  onPressed: () {
                                    notifier.setWalkmanCustomSkin(null);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('PRESET COLOR THEMES', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildThemeOptionChip(
                          label: 'Classic TPS-L2',
                          code: 'classicBlue',
                          swatch: const Color(0xFF3868A0),
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('classicBlue');
                          },
                        ),
                        _buildThemeOptionChip(
                          label: 'Stealth Black',
                          code: 'stealthBlack',
                          swatch: const Color(0xFF26282E),
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('stealthBlack');
                          },
                        ),
                        _buildThemeOptionChip(
                          label: 'Solar Yellow',
                          code: 'solarYellow',
                          swatch: const Color(0xFFF7CA45),
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('solarYellow');
                          },
                        ),
                        _buildThemeOptionChip(
                          label: 'Vintage Silver',
                          code: 'vintageSilver',
                          swatch: const Color(0xFFC4C8D2),
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('vintageSilver');
                          },
                        ),
                        _buildThemeOptionChip(
                          label: 'Tokyo Burgundy',
                          code: 'tokyoBurgundy',
                          swatch: const Color(0xFF6B233D),
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('tokyoBurgundy');
                          },
                        ),
                        _buildThemeOptionChip(
                          label: 'Cyber Accent',
                          code: 'customAccent',
                          swatch: curSettings.accentColor,
                          current: curSettings.walkmanCustomSkinPath != null ? '' : curSettings.walkmanChassisTheme,
                          onSelect: () {
                            notifier.setWalkmanCustomSkin(null);
                            notifier.setWalkmanChassisTheme('customAccent');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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

                    Text('HOTLINE TAB COLOR', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final color in [
                          const Color(0xFFF08A1C),
                          const Color(0xFFFF3B30),
                          const Color(0xFF00C7BE),
                          const Color(0xFFFFD60A),
                          curSettings.accentColor,
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

    final songs = playbackState.queue.isNotEmpty ? playbackState.queue : libraryState.allSongs;
    if (_step == 3 && playbackState.isPlaying && playbackState.currentTrack != null) {
      final curIdx = songs.indexWhere((t) => t.id == playbackState.currentTrack!.id);
      if (curIdx >= 0 && curIdx != _selectedTrackIndex) {
        _selectedTrackIndex = curIdx;
      }
    }
    final int safeIndex = songs.isNotEmpty ? _selectedTrackIndex.clamp(0, songs.length - 1) : 0;
    final AudioTrack? activeTapeTrack = songs.isNotEmpty
        ? songs[safeIndex]
        : playbackState.currentTrack;
    final track = activeTapeTrack;

    _syncReelAnimation(playbackState.isPlaying);

    MechanicalSoundService.instance.updateMotorAmbience(
      isPlayingMusic: playbackState.isPlaying,
      settings: settings,
    );

    final durationMs = playbackState.duration.inMilliseconds;
    final positionMs = playbackState.position.inMilliseconds;
    final double progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    final double leftRadius = 22.0 - (10.0 * progress);
    final double rightRadius = 12.0 + (10.0 * progress);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isNavbarTab ? Icons.home_outlined : Icons.arrow_back,
                      color: Colors.white70,
                    ),
                    tooltip: widget.isNavbarTab ? 'Home' : 'Back',
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.pauseClick,
                        settings: settings,
                      );
                      if (widget.isNavbarTab) {
                        widget.onNavigateHome?.call();
                      } else if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
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

            // Walkman & Cassette Case Stage Container
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
                                // Custom User Walkman Skin Image layer
                                if (settings.walkmanCustomSkinPath != null &&
                                    File(settings.walkmanCustomSkinPath!).existsSync())
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            File(settings.walkmanCustomSkinPath!),
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0x28FFFFFF),
                                                  Color(0x05000000),
                                                  Color(0x40000000),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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

                                // Recessed Cassette Bay (Deep Chamber)
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
                                        Positioned(
                                          left: 102,
                                          top: 110,
                                          child: _buildBaySpindle(),
                                        ),
                                        Positioned(
                                          left: 102,
                                          top: 240,
                                          child: _buildBaySpindle(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Cassette Swapper Navigation Pill (State 0 & 1)
                                if (_step <= 1 && songs.length > 1)
                                  Positioned(
                                    left: 20,
                                    top: 256,
                                    width: 220,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xEE121419),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: settings.accentColor.withAlpha(120), width: 1.0),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () => _swapCassette(-1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.chevron_left_rounded, size: 16, color: Colors.white70),
                                                  Text('PREV', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'TAPE ${safeIndex + 1}/${songs.length}',
                                            style: TextStyle(
                                              fontFamily: 'Courier',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: settings.accentColor,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _swapCassette(1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('NEXT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                                                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Cassette Jewel Case (Displays album art cover in State 0 & 1)
                                if (_step <= 1)
                                  Positioned(
                                    left: 20,
                                    top: 290,
                                    width: 220,
                                    height: 140,
                                    child: GestureDetector(
                                      onHorizontalDragEnd: (details) {
                                        if (details.primaryVelocity! < -100) {
                                          _swapCassette(1);
                                        } else if (details.primaryVelocity! > 100) {
                                          _swapCassette(-1);
                                        }
                                      },
                                      child: AnimatedBuilder(
                                        animation: _caseLidAnimController,
                                        builder: (context, _) {
                                          return _buildCassetteCase(
                                            track: track,
                                            openAngle: _caseLidAnimation.value,
                                            onTap: () {
                                              if (_step == 0) {
                                                _transitionToStep(1);
                                              } else if (_step == 1) {
                                                _transitionToStep(0);
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                // Animated Cassette Tape (Slides into the bay and rotates 90 deg)
                                AnimatedBuilder(
                                  animation: _cassetteAnimController,
                                  builder: (context, child) {
                                    final t = _cassetteProgress.value;
                                    // t=0 (in jewel case): y=285, x=10, rot=0 deg
                                    // t=1 (in walkman bay): y=135, x=10, rot=90 deg
                                    final currentY = 285.0 - (150.0 * t);
                                    final currentAngle = (math.pi / 2) * t;

                                    return Positioned(
                                      left: 10,
                                      top: currentY,
                                      width: 240,
                                      height: 150,
                                      child: Transform.rotate(
                                        angle: currentAngle,
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          onHorizontalDragEnd: _step <= 1
                                              ? (details) {
                                                  if (details.primaryVelocity! < -100) {
                                                    _swapCassette(1);
                                                  } else if (details.primaryVelocity! > 100) {
                                                    _swapCassette(-1);
                                                  }
                                                }
                                              : null,
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

                                // 3D Hinged Lid with 100% TRANSPARENT Acrylic Glass Window
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
                                              ? _buildLidFront(theme, settings)
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
                                      } else if (_step == 2) {
                                        _transitionToStep(1);
                                      }
                                    },
                                    onPlay: () {
                                      if (_step == 3) {
                                        if (playbackState.isPlaying) {
                                          ref.read(playbackNotifierProvider.notifier).pause();
                                        } else {
                                          if (track != null) {
                                            if (playbackState.currentTrack?.id != track.id) {
                                              ref.read(playbackNotifierProvider.notifier).playTrack(
                                                track,
                                                queue: songs,
                                              );
                                            } else {
                                              ref.read(playbackNotifierProvider.notifier).resume();
                                            }
                                          } else if (songs.isNotEmpty) {
                                            ref.read(playbackNotifierProvider.notifier).playTrack(
                                              songs.first,
                                              queue: songs,
                                            );
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

            // Lower Digital Control Panel
            _buildLowerControlPanel(
              settings: settings,
              playbackState: playbackState,
              trackTitle: track?.title,
              onEject: _ejectAndSwap,
              onGoNext: () {
                if (_step < 3) {
                  _transitionToStep(_step + 1);
                } else {
                  final isPlaying = playbackState.isPlaying;
                  MechanicalSoundService.instance.playMechanicalSound(
                    isPlaying ? MechanicalSoundType.pauseClick : MechanicalSoundType.playClack,
                    settings: settings,
                  );
                  if (isPlaying) {
                    ref.read(playbackNotifierProvider.notifier).pause();
                  } else {
                    if (track != null) {
                      if (playbackState.currentTrack?.id != track.id) {
                        ref.read(playbackNotifierProvider.notifier).playTrack(
                          track,
                          queue: songs,
                        );
                      } else {
                        ref.read(playbackNotifierProvider.notifier).resume();
                      }
                    } else if (songs.isNotEmpty) {
                      ref.read(playbackNotifierProvider.notifier).playTrack(
                        songs.first,
                        queue: songs,
                      );
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

  /// 100% Transparent Acrylic Glass Window on Lid
  Widget _buildLidFront(WalkmanThemeData theme, AppSettings settings) {
    const windowRect = Rect.fromLTWH(16, 20, 188, 290);

    return CustomPaint(
      painter: LidCutoutPainter(
        frameColor: theme.lidFrontColor,
        windowRect: windowRect,
      ),
      child: SizedBox(
        width: 220,
        height: 380,
        child: Stack(
          children: [
            // Custom User Skin Image Layer on Lid Frame (window cut out with evenOdd path)
            if (settings.walkmanCustomSkinPath != null &&
                File(settings.walkmanCustomSkinPath!).existsSync())
              Positioned.fill(
                child: ClipPath(
                  clipper: const LidCutoutClipper(windowRect),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(settings.walkmanCustomSkinPath!),
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x22FFFFFF),
                              Color(0x00000000),
                              Color(0x35000000),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Transparent Acrylic Glass Reflection Sheen
            Positioned.fromRect(
              rect: windowRect,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x32FFFFFF),
                        Color(0x06FFFFFF),
                        Color(0x18FFFFFF),
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Bold Italic "WALKMAN" Lettering on the bottom frame
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
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

  /// Cassette Jewel Case with opening J-card cover
  Widget _buildCassetteCase({
    required AudioTrack? track,
    required double openAngle,
    required VoidCallback onTap,
  }) {
    final title = track?.title ?? 'Rewind Tape';
    final artist = track?.artist ?? 'Analog Sound System';
    final album = track?.album ?? 'Vintage Cassette';

    final isFrontFacing = openAngle.abs() < (math.pi / 2);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        height: 140,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Base Tray
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E2026), Color(0xFF101115)],
                ),
                border: Border.all(color: Colors.white24, width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),

            // Hinged J-Card Cover
            Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(openAngle),
              child: isFrontFacing
                  ? _buildCaseCoverFront(track, title, artist, album)
                  : _buildCaseCoverBack(title, artist, album),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCoverFront(AudioTrack? track, String title, String artist, String album) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F222A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(2, 4)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Album Artwork Image covering J-card
          if (track != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: ArtworkWidget(
                id: track.albumId ?? int.tryParse(track.id),
                customArtPath: track.customArtPath,
                title: title,
                artist: artist,
                size: 220,
                borderRadius: 5,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                ),
              ),
              child: const Icon(Icons.album, size: 64, color: Colors.white24),
            ),

          // Title & Artist Bottom Strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xEE090A0D), Color(0x00090A0D)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clear Acrylic Sheen Reflection
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x35FFFFFF),
                    Color(0x05FFFFFF),
                    Color(0x18FFFFFF),
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCoverBack(String title, String artist, String album) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141519),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'J-CARD INDEX',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.tapeAmber,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 9, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo-Realistic Cassette Tape with Song Album Image & Rotating Spool Hubs
  Widget _buildRealisticCassette({
    required AudioTrack? track,
    required bool isPlaying,
    required double leftRadius,
    required double rightRadius,
    required double rotationAngle,
  }) {
    final title = track?.title ?? 'Rewind Hi-Fi Demo';
    final artist = track?.artist ?? 'Analog Sound System';

    return Container(
      width: 240,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C20),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withAlpha(25), width: 1.0),
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

          // Cassette Face Label with Full-Bleed Album Artwork Banner!
          Positioned(
            left: 10,
            right: 10,
            top: 8,
            height: 106,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF24262E),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // 1. Full-Bleed Album Artwork Image / Banner
                    Positioned.fill(
                      child: track != null
                          ? (track.customArtPath != null && File(track.customArtPath!).existsSync()
                              ? Image.file(
                                  File(track.customArtPath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : ArtworkWidget(
                                  id: track.albumId ?? int.tryParse(track.id),
                                  customArtPath: track.customArtPath,
                                  title: track.title,
                                  artist: track.artist,
                                  size: 220,
                                  borderRadius: 5,
                                ))
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                                ),
                              ),
                              child: const Icon(Icons.music_note, color: Colors.white24, size: 48),
                            ),
                    ),

                    // 2. Vintage Tape Sticker Gradient Overlay for Contrast & Readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(180),
                              Colors.black.withAlpha(30),
                              Colors.black.withAlpha(190),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 3. Track Title & Artist across top header
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(190),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Colors.white38, width: 0.8),
                            ),
                            child: const Text(
                              'SIDE A',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                ),
                                Text(
                                  artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withAlpha(220),
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'REWIND C-90',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Center Clear Pill Inspection Cutout (Spools + Rotating Hubs)
                    Positioned(
                      left: 35,
                      top: 48,
                      width: 150,
                      height: 46,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14151A),
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: Colors.white12, width: 0.8),
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

                          // Left Spool Hub (Rotates during playback)
                          Positioned(
                            left: 9,
                            child: Transform.rotate(
                              angle: rotationAngle,
                              child: _buildSpoolHub(),
                            ),
                          ),

                          // Right Spool Hub (Rotates during playback)
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
        ),

          // Bottom Trapezoid Head Cavity Foot
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
    required VoidCallback onEject,
    required VoidCallback onGoNext,
    required VoidCallback onBack,
  }) {
    String statusMsg = '';
    String actionLabel = '';
    IconData actionIcon = Icons.arrow_forward;

    switch (_step) {
      case 0:
        statusMsg = 'Chassis lid closed. Tap OPEN LID.';
        actionLabel = 'OPEN LID';
        actionIcon = Icons.lock_open_rounded;
        break;
      case 1:
        statusMsg = 'Lid open. Swap tape or tap INSERT TAPE.';
        actionLabel = 'INSERT TAPE';
        actionIcon = Icons.vertical_align_bottom_rounded;
        break;
      case 2:
        statusMsg = 'Cassette loaded in bay. Close lid to listen.';
        actionLabel = 'CLOSE LID';
        actionIcon = Icons.lock_outline_rounded;
        break;
      case 3:
      default:
        if (playbackState.isPlaying) {
          statusMsg = trackTitle != null ? 'Playing: $trackTitle' : 'Playing';
          actionLabel = 'PAUSE';
          actionIcon = Icons.pause_rounded;
        } else {
          statusMsg = trackTitle != null ? 'Ready: $trackTitle' : 'Ready to play';
          actionLabel = 'PLAY';
          actionIcon = Icons.play_arrow_rounded;
        }
        break;
    }

    final isLightAccent = ThemeData.estimateBrightnessForColor(settings.accentColor) == Brightness.light;
    final buttonFg = isLightAccent ? const Color(0xFF101115) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

          const SizedBox(height: 6),

          Text(
            statusMsg,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              if (_step >= 2) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onEject,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.tapeAmber),
                  label: const Text(
                    'SWAP TAPE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.tapeAmber),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tapeAmber,
                    side: const BorderSide(color: AppColors.tapeAmber, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onGoNext,
                icon: Icon(actionIcon, size: 18, color: buttonFg),
                label: Text(
                  actionLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.8,
                    color: buttonFg,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.accentColor,
                  foregroundColor: buttonFg,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

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

/// Custom painter for the Walkman door with a transparent acrylic glass cutout
class LidCutoutPainter extends CustomPainter {
  final Color frameColor;
  final Rect windowRect;

  LidCutoutPainter({
    required this.frameColor,
    required this.windowRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    final innerRRect = RRect.fromRectAndRadius(
      windowRect,
      const Radius.circular(6),
    );

    // Punch out the window hole using even-odd fill!
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outerRRect)
      ..addRRect(innerRRect);

    final fillPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Exterior frame bevel
    final outerBorder = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(outerRRect, outerBorder);

    // Window acrylic rim bevel
    final innerBorder = Paint()
      ..color = Colors.white.withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(innerRRect, innerBorder);
  }

  @override
  bool shouldRepaint(covariant LidCutoutPainter oldDelegate) {
    return oldDelegate.frameColor != frameColor || oldDelegate.windowRect != windowRect;
  }
}

/// Custom clipper to punch out the transparent acrylic inspection window on the lid
class LidCutoutClipper extends CustomClipper<Path> {
  final Rect windowRect;
  const LidCutoutClipper(this.windowRect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)))
      ..addRRect(RRect.fromRectAndRadius(windowRect, const Radius.circular(6)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant LidCutoutClipper oldClipper) => oldClipper.windowRect != windowRect;
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
