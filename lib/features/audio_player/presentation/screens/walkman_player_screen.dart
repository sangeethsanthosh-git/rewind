import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/add_to_tape_modal.dart';
import 'package:spool/core/widgets/cassette_door_compartment.dart';
import 'package:spool/core/widgets/walkman_mechanical_button.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

class WalkmanPlayerScreen extends ConsumerStatefulWidget {
  const WalkmanPlayerScreen({super.key});

  @override
  ConsumerState<WalkmanPlayerScreen> createState() => _WalkmanPlayerScreenState();
}

class _WalkmanPlayerScreenState extends ConsumerState<WalkmanPlayerScreen> {
  final GlobalKey<CassetteDoorCompartmentState> _doorKey = GlobalKey();
  double _volumeLevel = 0.8;

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final track = playbackState.currentTrack;

    // Update motor ambience on state change
    MechanicalSoundService.instance.updateMotorAmbience(
      isPlayingMusic: playbackState.isPlaying,
      settings: settings,
    );

    return Scaffold(
      backgroundColor: themePalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'PORTABLE CASSETTE PLAYER',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  Row(
                    children: [
                      if (track != null)
                        IconButton(
                          icon: const Icon(Icons.playlist_add_rounded, color: AppColors.tapeAmber),
                          tooltip: 'Record to Tape',
                          onPressed: () {
                            AddToTapeModal.show(context, ref, track);
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _doorKey.currentState?.isEjected == true ? Icons.file_download_outlined : Icons.eject_outlined,
                          color: AppColors.tapeAmber,
                        ),
                        tooltip: _doorKey.currentState?.isEjected == true ? 'Insert Tape / Close Door' : 'Eject Cassette',
                        onPressed: () {
                          setState(() {
                            _doorKey.currentState?.toggleEject();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Walkman Chassis (Brushed aluminum body inspired by image 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFD6D6DE), // Brushed silver top
                      Color(0xFFB0B0B8),
                      Color(0xFF9898A0), // Metallic body
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8E8EE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(240),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Walkman Faceplate Header (SOFT - WOOL CHALLENGE & Battery Meter)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'WALKMAN',
                                style: AppTypography.displaySmall.copyWith(
                                  color: const Color(0xFF222226),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Power LED
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: playbackState.isPlaying ? AppColors.tapeAmber : const Color(0xFF55555C),
                                  boxShadow: playbackState.isPlaying
                                      ? [
                                          BoxShadow(
                                            color: AppColors.tapeAmber.withAlpha(200),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          // Vintage LCD Tape Counter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A342B), // Greenish LCD background
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF1E261F), width: 1.2),
                            ),
                            child: Text(
                              '${Formatters.formatDuration(playbackState.position)} / ${Formatters.formatDuration(playbackState.duration)}',
                              style: AppTypography.monoSmall.copyWith(
                                color: const Color(0xFF9DE0A8), // LCD digital green
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),

                          // Battery 4-segment LED bar
                          Row(
                            children: [
                              Text(
                                'BATT',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 8,
                                  color: const Color(0xFF33333A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 28,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222226),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                padding: const EdgeInsets.all(1),
                                child: Row(
                                  children: [
                                    for (int i = 0; i < 4; i++)
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                          color: AppColors.tapeGreen,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Recessed Cassette Compartment Window with Horizontal Swipe to Change Song
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < -250) {
                              MechanicalSoundService.instance.playMechanicalSound(
                                MechanicalSoundType.skipClick,
                                settings: settings,
                              );
                              ref.read(playbackNotifierProvider.notifier).skipToNext();
                            } else if (details.primaryVelocity! > 250) {
                              MechanicalSoundService.instance.playMechanicalSound(
                                MechanicalSoundType.skipClick,
                                settings: settings,
                              );
                              ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                            }
                          }
                        },
                        child: Center(
                          child: CassetteDoorCompartment(
                            key: _doorKey,
                            track: track,
                            isPlaying: playbackState.isPlaying,
                            position: playbackState.position,
                            duration: playbackState.duration,
                            settings: settings,
                            onEjected: () {
                              ref.read(playbackNotifierProvider.notifier).pause();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Analog Rotary Volume Wheel & Info Strip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track?.title ?? 'NO CASSETTE INSERTED',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.displaySmall.copyWith(
                                    fontSize: 14,
                                    color: const Color(0xFF1B1B20),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  track?.artist ?? 'Select music to play',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF44444C),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Analog Thumbwheel Volume Dial
                          Column(
                            children: [
                              Text(
                                'VOL',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 8,
                                  color: const Color(0xFF2E2E35),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                height: 26,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    activeTrackColor: const Color(0xFF222226),
                                    inactiveTrackColor: const Color(0xFF7A7A84),
                                    thumbColor: settings.accentColor,
                                  ),
                                  child: Slider(
                                    value: _volumeLevel,
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
                    ),

                    // Heavy Metallic Button Bank (PREV, REW, STOP, PLAY, FF, NEXT)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF787882), // Darker chassis inset
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                        border: Border(top: BorderSide(color: Color(0xFF55555C), width: 1.2)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final totalW = constraints.maxWidth;
                          final btnW = ((totalW - 20) / 6.6).clamp(36.0, 56.0);
                          final playW = (btnW * 1.25).clamp(46.0, 68.0);
                          final btnH = (btnW * 1.25).clamp(48.0, 68.0);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // PREV
                              WalkmanMechanicalButton(
                                icon: Icons.skip_previous,
                                label: 'PREV',
                                width: btnW,
                                height: btnH,
                                soundType: MechanicalSoundType.skipClick,
                                settings: settings,
                                onPressed: () {
                                  ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                                },
                              ),
                              // REWIND
                              WalkmanMechanicalButton(
                                icon: Icons.fast_rewind,
                                label: 'REW',
                                width: btnW,
                                height: btnH,
                                soundType: MechanicalSoundType.skipClick,
                                settings: settings,
                                onPressed: () {
                                  final current = playbackState.position;
                                  final target = current - const Duration(seconds: 10);
                                  ref.read(playbackNotifierProvider.notifier).seek(
                                    target > Duration.zero ? target : Duration.zero,
                                  );
                                },
                              ),
                              // STOP
                              WalkmanMechanicalButton(
                                icon: Icons.stop,
                                label: 'STOP',
                                width: btnW,
                                height: btnH,
                                soundType: MechanicalSoundType.pauseClick,
                                settings: settings,
                                onPressed: () {
                                  ref.read(playbackNotifierProvider.notifier).pause();
                                },
                              ),
                              // PLAY (Large prominent primary button!)
                              WalkmanMechanicalButton(
                                icon: playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                                label: playbackState.isPlaying ? 'PAUSE' : 'PLAY',
                                isPrimary: true,
                                width: playW,
                                height: btnH,
                                isDepressed: playbackState.isPlaying,
                                accentColor: settings.accentColor,
                                soundType: playbackState.isPlaying
                                    ? MechanicalSoundType.pauseClick
                                    : MechanicalSoundType.playClack,
                                settings: settings,
                                onPressed: () {
                                  ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                                },
                              ),
                              // FAST FORWARD
                              WalkmanMechanicalButton(
                                icon: Icons.fast_forward,
                                label: 'F.F.',
                                width: btnW,
                                height: btnH,
                                soundType: MechanicalSoundType.skipClick,
                                settings: settings,
                                onPressed: () {
                                  final current = playbackState.position;
                                  final duration = playbackState.duration;
                                  final target = current + const Duration(seconds: 10);
                                  ref.read(playbackNotifierProvider.notifier).seek(
                                    target < duration ? target : duration,
                                  );
                                },
                              ),
                              // NEXT
                              WalkmanMechanicalButton(
                                icon: Icons.skip_next,
                                label: 'NEXT',
                                width: btnW,
                                height: btnH,
                                soundType: MechanicalSoundType.skipClick,
                                settings: settings,
                                onPressed: () {
                                  ref.read(playbackNotifierProvider.notifier).skipToNext();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
