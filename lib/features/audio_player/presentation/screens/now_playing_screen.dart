import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/core/utils/banner_picker_helper.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/add_to_tape_modal.dart';
import 'package:spool/core/widgets/analog_vu_meter.dart';
import 'package:spool/core/widgets/artwork_widget.dart';
import 'package:spool/core/widgets/cassette_tape_widget.dart';
import 'package:spool/core/widgets/crt_waveform_visualizer.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/audio_player/domain/playback_state.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/audio_player/presentation/screens/walkman_player_screen.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

enum NowPlayingVisualMode {
  banner,
  cassette,
  crtOscilloscope,
}

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  NowPlayingVisualMode _visualMode = NowPlayingVisualMode.banner;
  bool _isTransparentCassette = true;
  double _dragPosition = 0.0;
  bool _isDragging = false;
  int _slideDirection = 1; // 1 for next (leftwards), -1 for prev (rightwards)

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final track = playbackState.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: themePalette.background,
        appBar: AppBar(
          backgroundColor: themePalette.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('NOW PLAYING', style: AppTypography.displaySmall.copyWith(fontSize: 16)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_off_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No Track Selected', style: AppTypography.displaySmall),
              const SizedBox(height: 8),
              Text('Choose a song from your library or queue', style: AppTypography.bodySmall),
            ],
          ),
        ),
      );
    }

    final duration = playbackState.duration;
    final position = _isDragging
        ? Duration(milliseconds: _dragPosition.toInt())
        : playbackState.position;
    final remaining = duration > position ? duration - position : Duration.zero;

    return Scaffold(
      backgroundColor: themePalette.background,
      body: Stack(
        children: [
          // Dynamic Ambient Song Canvas or Custom Wallpaper Backdrop
          Positioned.fill(
            child: _buildNowPlayingBackground(settings, themePalette, track),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Fitted with Single-line Album Truncation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 28, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: AppTypography.monoSmall.copyWith(
                                letterSpacing: 2,
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.album.isNotEmpty ? track.album : track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Record to Tape Action
                          IconButton(
                            icon: const Icon(Icons.playlist_add_rounded, color: AppColors.tapeAmber, size: 22),
                            tooltip: 'Record to Tape',
                            onPressed: () {
                              AddToTapeModal.show(context, ref, track);
                            },
                          ),
                          // Walkman Chassis Mode
                          IconButton(
                            icon: const Icon(Icons.radio_outlined, color: AppColors.neonOrange, size: 22),
                            tooltip: 'Open Walkman Chassis',
                            onPressed: () {
                              MechanicalSoundService.instance.playMechanicalSound(
                                MechanicalSoundType.doorLatch,
                                settings: settings,
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const WalkmanPlayerScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

            // Mode Selector Pill (Banner / Cassette / CRT)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeTab('BANNER', NowPlayingVisualMode.banner, Icons.image_outlined),
                  _buildModeTab('CASSETTE', NowPlayingVisualMode.cassette, Icons.subtitles_outlined),
                  _buildModeTab('OSCILLO', NowPlayingVisualMode.crtOscilloscope, Icons.graphic_eq_rounded),
                ],
              ),
            ),

            // Error Banner if playback failed
            if (playbackState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.vinylRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.vinylRed.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.vinylRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        playbackState.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

            // Swappable Visual Area (Swipe Left/Right to change song)
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -250) {
                      // Swiped left -> Next song
                      setState(() => _slideDirection = 1);
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).skipToNext();
                    } else if (details.primaryVelocity! > 250) {
                      // Swiped right -> Previous song
                      setState(() => _slideDirection = -1);
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                    }
                  }
                },
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(_slideDirection * 0.35, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey('${track.id}_${_visualMode.name}'),
                      child: _buildVisualContent(track, playbackState, position, duration),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Analog VU Meter & Technical Specs Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnalogVuMeter(isPlaying: playbackState.isPlaying),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                    ),
                    child: Text(
                      Formatters.formatTechnicalSpecs(
                        extension: track.fileExtension,
                        bitrate: track.bitrate,
                        sampleRate: track.sampleRate,
                        bitDepth: track.bitDepth,
                        isLossless: track.isLossless,
                      ),
                      style: AppTypography.monoSmall.copyWith(
                        color: track.isLossless ? AppColors.tapeAmber : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Track Header & Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySmall.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add to Tape Button
                  IconButton(
                    icon: const Icon(Icons.album_outlined, color: AppColors.tapeAmber, size: 24),
                    tooltip: 'Record to Tape',
                    onPressed: () => AddToTapeModal.show(context, ref, track),
                  ),
                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      track.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: track.isFavorite ? AppColors.vinylRed : AppColors.textMuted,
                      size: 26,
                    ),
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).toggleFavorite(track);
                    },
                  ),
                  // Queue Button
                  IconButton(
                    icon: const Icon(Icons.queue_music, color: AppColors.textSecondary, size: 26),
                    onPressed: () => _showQueueModal(context, playbackState),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Seek Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.neonOrange,
                      inactiveTrackColor: AppColors.surfaceElevated,
                    ),
                    child: Slider(
                      value: position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                      max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                      onChangeStart: (val) {
                        setState(() {
                          _isDragging = true;
                          _dragPosition = val;
                        });
                      },
                      onChanged: (val) {
                        setState(() {
                          _dragPosition = val;
                        });
                      },
                      onChangeEnd: (val) {
                        _isDragging = false;
                        ref.read(playbackNotifierProvider.notifier).seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Formatters.formatDuration(position), style: AppTypography.monoSmall),
                        Text('SWIPE ART TO SWAP SONG', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted.withAlpha(120), fontSize: 9)),
                        Text('-${Formatters.formatDuration(remaining)}', style: AppTypography.monoSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tactile Transport Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playbackState.isShuffleEnabled ? AppColors.neonOrange : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).toggleShuffle();
                    },
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 36),
                    onPressed: () {
                      setState(() => _slideDirection = -1);
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).skipToPrevious();
                    },
                  ),
                  // Big Tactile Play/Pause Clack Button
                  GestureDetector(
                    onTap: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        playbackState.isPlaying
                            ? MechanicalSoundType.pauseClick
                            : MechanicalSoundType.playClack,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                    },
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppColors.parchment,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonOrange.withAlpha(70),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          playbackState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.textOnCream,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 36),
                    onPressed: () {
                      setState(() => _slideDirection = 1);
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).skipToNext();
                    },
                  ),
                  // Repeat
                  IconButton(
                    icon: Icon(
                      playbackState.repeatMode == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: playbackState.repeatMode != LoopMode.off ? AppColors.neonOrange : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: () {
                      MechanicalSoundService.instance.playMechanicalSound(
                        MechanicalSoundType.skipClick,
                        settings: settings,
                      );
                      ref.read(playbackNotifierProvider.notifier).toggleRepeat();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBackground(
    dynamic settings,
    ThemePalette themePalette,
    AudioTrack track,
  ) {
    Widget? backgroundContent;

    if (settings.customBackgroundImagePath != null &&
        File(settings.customBackgroundImagePath!).existsSync()) {
      backgroundContent = Image.file(
        File(settings.customBackgroundImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (settings.useSongBannerCanvas == true) {
      if (track.customArtPath != null &&
          File(track.customArtPath!).existsSync()) {
        backgroundContent = Image.file(
          File(track.customArtPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (track.albumId != null) {
        backgroundContent = ArtworkWidget(
          id: track.albumId,
          size: double.infinity,
          borderRadius: 0,
          title: track.title,
          artist: track.artist,
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
                settings.customBackgroundImagePath ?? track.id,
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
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
        ],
      );
    }

    return Container(color: themePalette.background);
  }

  Widget _buildModeTab(String label, NowPlayingVisualMode mode, IconData icon) {
    final isSelected = _visualMode == mode;
    return GestureDetector(
      onTap: () {
        final settings = ref.read(settingsNotifierProvider);
        MechanicalSoundService.instance.playMechanicalSound(
          MechanicalSoundType.skipClick,
          settings: settings,
        );
        setState(() => _visualMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.monoSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualContent(
    AudioTrack track,
    SpoolPlaybackState playbackState,
    Duration position,
    Duration duration,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        final availableW = constraints.maxWidth;
        final bannerSize = math.min(availableH * 0.92, math.min(availableW * 0.88, 300.0));

        switch (_visualMode) {
          case NowPlayingVisualMode.banner:
            return _buildMusicBanner(track, size: bannerSize);
          case NowPlayingVisualMode.cassette:
            final cassetteMaxW = math.min(availableW * 0.92, 420.0);
            final cassetteMaxH = availableH * 0.78;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cassetteMaxW,
                    maxHeight: cassetteMaxH,
                  ),
                  child: CassetteTapeWidget(
                    track: track,
                    isPlaying: playbackState.isPlaying,
                    position: position,
                    duration: duration,
                    isTransparentShell: _isTransparentCassette,
                    labelColor: AppColors.spinePalette[track.title.hashCode.abs() % AppColors.spinePalette.length],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() => _isTransparentCassette = !_isTransparentCassette);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      _isTransparentCassette ? 'SHELL: CLEAR C-60' : 'SHELL: MATTE BLACK',
                      style: AppTypography.monoSmall.copyWith(fontSize: 9, color: AppColors.tapeAmber),
                    ),
                  ),
                ),
              ],
            );
          case NowPlayingVisualMode.crtOscilloscope:
            final scopeH = math.min(availableH * 0.75, 210.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CrtWaveformVisualizer(
                    isPlaying: playbackState.isPlaying,
                    height: scopeH,
                    beamColor: const Color(0xFF00FF88),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'OSCILLOSCOPE CRT STEREO MONITOR',
                    style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Widget _buildMusicBanner(AudioTrack track, {double size = 280.0}) {
    final vinylSize = size * 0.9;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(220),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vinyl record peeking out from sleeve
          Positioned(
            right: 0,
            child: Container(
              width: vinylSize,
              height: vinylSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF111114),
              ),
            ),
          ),
          // Banner Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ArtworkWidget(
              id: track.albumId,
              customArtPath: track.customArtPath,
              size: size,
              title: track.title,
              artist: track.artist,
              onAddBanner: () {
                BannerPickerHelper.pickAndSetBanner(context: context, ref: ref, track: track);
              },
            ),
          ),
          // Edit Banner Image Pill Button
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  BannerPickerHelper.pickAndSetBanner(context: context, ref: ref, track: track);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(170),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'BANNER',
                        style: AppTypography.monoSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQueueModal(BuildContext context, SpoolPlaybackState playbackState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PLAYBACK QUEUE (${playbackState.queue.length})',
                style: AppTypography.monoSmall.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: playbackState.queue.length,
                  itemBuilder: (context, index) {
                    final item = playbackState.queue[index];
                    final isCurrent = index == playbackState.currentIndex;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Text(
                        '${index + 1}',
                        style: AppTypography.monoSmall.copyWith(
                          color: isCurrent ? AppColors.neonOrange : AppColors.textMuted,
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isCurrent ? AppColors.neonOrange : AppColors.textPrimary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        item.artist,
                        maxLines: 1,
                        style: AppTypography.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          ref.read(playbackNotifierProvider.notifier).removeFromQueue(index);
                        },
                      ),
                      onTap: () {
                        ref.read(playbackNotifierProvider.notifier).playAt(index);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
