import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/audio_player/presentation/screens/now_playing_screen.dart';
import 'package:spool/features/home/presentation/widgets/responsive_song_stack.dart';
import 'package:spool/features/library/presentation/providers/library_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int targetTabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final allSongs = libraryState.allSongs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header: App Name REWIND on the left
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'REWIND',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Scanning progress indicator banner
            if (libraryState.scanProgress?.isScanning == true)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.tapeAmber.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.tapeAmber),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        libraryState.scanProgress!.statusMessage,
                        style: AppTypography.monoSmall.copyWith(color: AppColors.tapeAmber, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

            // 3D Song Stack (Signature Home Screen UI)
            Expanded(
              child: Stack(
                children: [
                  ResponsiveSongStack(
                    tracks: allSongs,
                    onTrackTap: (track) {
                      ref.read(playbackNotifierProvider.notifier).playTrack(
                        track,
                        queue: allSongs,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NowPlayingScreen(),
                        ),
                      );
                    },
                  ),
                  if (allSongs.isEmpty && libraryState.scanProgress?.isScanning != true)
                    Positioned(
                      top: 12,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xEB1A1A22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.tapeAmber.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.tapeAmber, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Showing preview crate. Tap "Scan" or folder icon to index local files.',
                                style: AppTypography.monoSmall.copyWith(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(libraryNotifierProvider.notifier).rescan();
                              },
                              child: Text(
                                'SCAN NOW',
                                style: AppTypography.monoSmall.copyWith(
                                  color: AppColors.neonOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
          ],
        ),
      ),
    );
  }
}
