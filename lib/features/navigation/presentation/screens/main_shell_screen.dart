import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/utils/banner_picker_helper.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/artwork_widget.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/audio_player/presentation/screens/now_playing_screen.dart';
import 'package:spool/features/home/presentation/screens/home_screen.dart';
import 'package:spool/features/library/presentation/screens/folders_screen.dart';
import 'package:spool/features/library/presentation/screens/library_screen.dart';
import 'package:spool/features/search/presentation/screens/search_screen.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';
import 'package:spool/features/settings/presentation/screens/settings_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final hasActiveTrack = playbackState.currentTrack != null;

    final screens = [
      HomeScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const LibraryScreen(),
      const FoldersScreen(),
      const SearchScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: themePalette.background,
      body: Stack(
        children: [
          // Dynamic Ambient Song Canvas or Custom Wallpaper Backdrop
          Positioned.fill(
            child: _buildAppBackground(settings, themePalette, playbackState.currentTrack),
          ),

          // Current Page
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Floating Retro Now Playing Banner (Visible ONLY on Home Page, positioned snug above navigation bar)
          if (hasActiveTrack && _currentIndex == 0)
            Positioned(
              left: 8,
              right: 8,
              bottom: 4, // Positioned right near the bottom navigation bar
              child: _buildHomeNowPlayingBanner(playbackState, themePalette),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: themePalette.surfaceCard,
          border: Border(top: BorderSide(color: themePalette.borderSubtle, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: settings.accentColor,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.monoSmall.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTypography.monoSmall.copyWith(fontSize: 9),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'LIBRARY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'FOLDERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'SEARCH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'SETUP',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBackground(
    dynamic settings,
    ThemePalette themePalette,
    dynamic currentTrack,
  ) {
    Widget? backgroundContent;

    // 1. User uploaded custom wallpaper image
    if (settings.customBackgroundImagePath != null &&
        File(settings.customBackgroundImagePath!).existsSync()) {
      backgroundContent = Image.file(
        File(settings.customBackgroundImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    // 2. Dynamic Song Banner Canvas
    else if (settings.useSongBannerCanvas == true && currentTrack != null) {
      if (currentTrack.customArtPath != null &&
          File(currentTrack.customArtPath!).existsSync()) {
        backgroundContent = Image.file(
          File(currentTrack.customArtPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (currentTrack.albumId != null) {
        backgroundContent = ArtworkWidget(
          id: currentTrack.albumId,
          size: double.infinity,
          borderRadius: 0,
          title: currentTrack.title,
          artist: currentTrack.artist,
        );
      }
    }

    if (backgroundContent != null) {
      final double dimLevel = (settings.backgroundDimLevel as double? ?? 0.50).clamp(0.1, 0.95);
      final double blurSigma = (settings.backgroundBlurSigma as double? ?? 6.0).clamp(0.0, 30.0);

      final Widget filtered = blurSigma > 0.5
          ? ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Transform.scale(
                scale: 1.05 + (blurSigma / 180.0),
                child: backgroundContent,
              ),
            )
          : backgroundContent;

      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: themePalette.background),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            child: KeyedSubtree(
              key: ValueKey(
                settings.customBackgroundImagePath ??
                currentTrack?.id ??
                'default_bg',
              ),
              child: filtered,
            ),
          ),
          Container(
            color: Colors.black.withAlpha((dimLevel * 255).round()),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.25,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
        ],
      );
    }

    return Container(color: themePalette.background);
  }

  Widget _buildHomeNowPlayingBanner(dynamic playbackState, ThemePalette themePalette) {
    final track = playbackState.currentTrack!;
    final isPlaying = playbackState.isPlaying;
    final duration = playbackState.duration;
    final position = playbackState.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final settings = ref.watch(settingsNotifierProvider);
    final accentColor = settings.accentColor;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const NowPlayingScreen(),
            transitionsBuilder: (context, anim1, anim2, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themePalette.surfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themePalette.borderSubtle, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  // Compact Banner Artwork Image with "+ BANNER" Picker Button
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withAlpha(120), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(140),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: (track.customArtPath != null &&
                                  track.customArtPath!.isNotEmpty &&
                                  File(track.customArtPath!).existsSync())
                              ? Image.file(
                                  File(track.customArtPath!),
                                  fit: BoxFit.cover,
                                )
                              : ArtworkWidget(
                                  id: int.tryParse(track.id),
                                  albumId: track.albumId,
                                  customArtPath: track.customArtPath,
                                  size: 42,
                                  borderRadius: 7,
                                  title: track.title,
                                  artist: track.artist,
                                ),
                        ),
                      ),
                      // Quick Tap to Add / Change Banner
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            BannerPickerHelper.pickAndSetBanner(
                              context: context,
                              ref: ref,
                              track: track,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(220),
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 0.8),
                            ),
                            child: Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 10,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Compact 2-Line Track Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.tapeGreen,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${track.artist} • ${track.fileExtension.toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.formatDuration(position),
                              style: AppTypography.monoSmall.copyWith(
                                color: AppColors.tapeAmber,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Transport Buttons (Prev, Play/Pause, Next)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 20,
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary),
                        onPressed: () {
                          final settings = ref.read(settingsNotifierProvider);
                          MechanicalSoundService.instance.playMechanicalSound(
                            MechanicalSoundType.skipClick,
                            settings: settings,
                          );
                          ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                        },
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        iconSize: 28,
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: accentColor,
                        ),
                        onPressed: () {
                          final settings = ref.read(settingsNotifierProvider);
                          MechanicalSoundService.instance.playMechanicalSound(
                            isPlaying ? MechanicalSoundType.pauseClick : MechanicalSoundType.playClack,
                            settings: settings,
                          );
                          ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                        },
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        iconSize: 20,
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary),
                        onPressed: () {
                          final settings = ref.read(settingsNotifierProvider);
                          MechanicalSoundService.instance.playMechanicalSound(
                            MechanicalSoundType.skipClick,
                            settings: settings,
                          );
                          ref.read(playbackNotifierProvider.notifier).skipToNext();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Progress Bar on bottom of banner card
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.0,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

