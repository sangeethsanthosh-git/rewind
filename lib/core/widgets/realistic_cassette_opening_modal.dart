import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../services/mechanical_sound_service.dart';
import '../utils/banner_picker_helper.dart';
import '../utils/formatters.dart';
import 'add_to_tape_modal.dart';
import 'artwork_widget.dart';
import '../../features/audio_player/domain/audio_track.dart';
import '../../features/audio_player/presentation/providers/audio_player_provider.dart';
import '../../features/audio_player/presentation/screens/now_playing_screen.dart';
import '../../features/audio_player/presentation/screens/walkman_player_screen.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

class RealisticCassetteOpeningModal extends ConsumerStatefulWidget {
  final AudioTrack track;
  final List<AudioTrack> allTracks;
  final int initialIndex;

  const RealisticCassetteOpeningModal({
    super.key,
    required this.track,
    required this.allTracks,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required AudioTrack track,
    required List<AudioTrack> allTracks,
    int initialIndex = 0,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cassette Case',
      barrierColor: Colors.black.withAlpha(225),
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (context, anim1, anim2) {
        return RealisticCassetteOpeningModal(
          track: track,
          allTracks: allTracks,
          initialIndex: initialIndex,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<RealisticCassetteOpeningModal> createState() =>
      _RealisticCassetteOpeningModalState();
}

class _RealisticCassetteOpeningModalState
    extends ConsumerState<RealisticCassetteOpeningModal>
    with TickerProviderStateMixin {
  late final AnimationController _openController;
  late final AnimationController _spoolRotationController;
  late final Animation<double> _openAngleAnimation;
  late final Animation<double> _tapeSlideAnimation;

  late int _currentIndex;
  bool _isDraggingSeek = false;
  double _dragSeekMs = 0.0;
  bool _isTransparentShell = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.allTracks.isNotEmpty ? widget.allTracks.length - 1 : 0,
    );

    // Case opening hinge animation
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _openAngleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutBack),
    );

    _tapeSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Continuous spool rotation
    _spoolRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _openController.forward();
    _spoolRotationController.repeat();
  }

  @override
  void dispose() {
    _openController.dispose();
    _spoolRotationController.dispose();
    super.dispose();
  }

  void _closeCase() {
    final settings = ref.read(settingsNotifierProvider);
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.doorLatch,
      settings: settings,
    );
    HapticFeedback.mediumImpact();
    _openController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _skipNext() {
    if (widget.allTracks.isEmpty) return;
    final settings = ref.read(settingsNotifierProvider);
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: settings,
    );
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.allTracks.length;
    });
    final nextTrack = widget.allTracks[_currentIndex];
    ref.read(playbackNotifierProvider.notifier).playTrack(
          nextTrack,
          queue: widget.allTracks,
        );
  }

  void _skipPrev() {
    if (widget.allTracks.isEmpty) return;
    final settings = ref.read(settingsNotifierProvider);
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: settings,
    );
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.allTracks.length) %
          widget.allTracks.length;
    });
    final prevTrack = widget.allTracks[_currentIndex];
    ref.read(playbackNotifierProvider.notifier).playTrack(
          prevTrack,
          queue: widget.allTracks,
        );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final activeTrack = playbackState.currentTrack ??
        (widget.allTracks.isNotEmpty
            ? widget.allTracks[_currentIndex]
            : widget.track);

    // Spin or pause spools with playback state
    if (playbackState.isPlaying && !_spoolRotationController.isAnimating) {
      _spoolRotationController.repeat();
    } else if (!playbackState.isPlaying &&
        _spoolRotationController.isAnimating) {
      _spoolRotationController.stop();
    }

    final duration = playbackState.duration;
    final position = _isDraggingSeek
        ? Duration(milliseconds: _dragSeekMs.toInt())
        : playbackState.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;

            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 860 : 440,
                  maxHeight: constraints.maxHeight * 0.94,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141419),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(250),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Bar: Case Header & Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.tapeGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SPOOL RETRO CASSETTE JEWEL CASE',
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.tapeAmber,
                              letterSpacing: 1.2,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Shell Style Toggle
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: 'Toggle Cassette Shell',
                            icon: Icon(
                              _isTransparentShell
                                  ? Icons.lens_blur_rounded
                                  : Icons.circle_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isTransparentShell = !_isTransparentShell;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          // Open Walkman Screen
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: 'Open Walkman Deck',
                            icon: const Icon(
                              Icons.radio_outlined,
                              color: AppColors.neonOrange,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WalkmanPlayerScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Open Now Playing Screen
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: 'Open Now Playing Screen',
                            icon: const Icon(
                              Icons.graphic_eq_rounded,
                              color: AppColors.tapeAmber,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const NowPlayingScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Close Case Button
                          IconButton(
                            iconSize: 22,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: 'Close Cassette Case',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: _closeCase,
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: AppColors.borderSubtle, height: 1),

                    // Main Open Cassette Case Stage
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: AnimatedBuilder(
                          animation: _openAngleAnimation,
                          builder: (context, _) {
                            final openVal = _openAngleAnimation.value;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // J-Card Case Cover (Left)
                                      Expanded(
                                        flex: 5,
                                        child: _buildJCardCover(
                                          activeTrack,
                                          openVal: openVal,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Cassette Tape in Tray (Right)
                                      Expanded(
                                        flex: 6,
                                        child: _buildCassetteInTray(
                                          track: activeTrack,
                                          playbackState: playbackState,
                                          position: position,
                                          duration: duration,
                                          progress: progress,
                                          openVal: openVal,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // J-Card Case Cover (Top)
                                      _buildJCardCover(
                                        activeTrack,
                                        openVal: openVal,
                                        isStacked: true,
                                      ),
                                      const SizedBox(height: 16),
                                      // Cassette Tape in Tray (Bottom)
                                      _buildCassetteInTray(
                                        track: activeTrack,
                                        playbackState: playbackState,
                                        position: position,
                                        duration: duration,
                                        progress: progress,
                                        openVal: openVal,
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ),
                    ),

                    // Bottom Tape Deck Transport Controls
                    _buildTransportBar(
                      playbackState: playbackState,
                      settings: settings,
                      track: activeTrack,
                      position: position,
                      duration: duration,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The J-Card jewel case front cover with banner artwork, paper texture, and retro typography
  Widget _buildJCardCover(
    AudioTrack track, {
    required double openVal,
    bool isStacked = false,
  }) {
    final hash = track.title.hashCode.abs();
    final accent = AppColors.spinePalette[hash % AppColors.spinePalette.length];

    // 3D perspective rotation around the left hinge
    final hingeTransform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(isStacked ? 0.0 : -(1.0 - openVal) * (math.pi / 2.2));

    return Transform(
      alignment: Alignment.centerLeft,
      transform: hingeTransform,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4EDE2), // Vintage warm cream paper
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD0C3B2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 18,
              offset: const Offset(4, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top J-card header line (Inspired by reference Image 1 & 4)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: const Color(0xFFECE3D2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'SPOOL ANALOG ARCHIVE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoSmall.copyWith(
                          color: const Color(0xFF5A4D3E),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'STEREO C-60',
                      style: AppTypography.monoSmall.copyWith(
                        color: const Color(0xFF5A4D3E),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Banner Artwork Photo (Framed film photo aesthetic)
              Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF33333A),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(90),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: (track.customArtPath != null &&
                                  track.customArtPath!.isNotEmpty &&
                                  File(track.customArtPath!).existsSync())
                              ? Image.file(
                                  File(track.customArtPath!),
                                  fit: BoxFit.cover,
                                )
                              : (track.albumId != null
                                  ? ArtworkWidget(
                                      id: track.albumId,
                                      size: double.infinity,
                                      borderRadius: 0,
                                      title: track.title,
                                      artist: track.artist,
                                    )
                                  : _buildPlaceholderCover(accent, track)),
                        ),

                        // Edit Banner Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                BannerPickerHelper.pickAndSetBanner(
                                  context: context,
                                  ref: ref,
                                  track: track,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      size: 11,
                                      color: Colors.white,
                                    ),
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
                  ),
                ),
              ),

              // Editorial Typography on J-Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoSmall.copyWith(
                        color: const Color(0xFF7A6A55),
                        letterSpacing: 2.0,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B1813),
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Color(0xFF5A4D3E),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Retro technical specs strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DAC9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFC7B9A3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            track.fileExtension.toUpperCase(),
                            style: AppTypography.monoSmall.copyWith(
                              color: const Color(0xFF2E241A),
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              track.isLossless
                                  ? 'HI-RES MASTER'
                                  : 'ANALOG HI-BIAS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.monoSmall.copyWith(
                                color: const Color(0xFF6B5C49),
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatDurationMs(track.durationMs),
                            style: AppTypography.monoSmall.copyWith(
                              color: const Color(0xFF2E241A),
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The clear molded jewel box tray containing the rotating cassette tape
  Widget _buildCassetteInTray({
    required AudioTrack track,
    required dynamic playbackState,
    required Duration position,
    required Duration duration,
    required double progress,
    required double openVal,
  }) {
    final hash = track.title.hashCode.abs();
    final accent = AppColors.spinePalette[hash % AppColors.spinePalette.length];

    // Cassette emerges slightly from the tray on open
    final slideY = (1.0 - _tapeSlideAnimation.value) * 16.0;

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B22), // Molded smoked acrylic tray
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(200),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Realistic Compact Audio Cassette
            AspectRatio(
              aspectRatio: 1.58,
              child: Container(
                decoration: BoxDecoration(
                  color: _isTransparentShell
                      ? const Color(0x352B3545)
                      : const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isTransparentShell
                        ? Colors.white30
                        : const Color(0xFF383842),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(180),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner screws
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _CassetteScrew(),
                    ),
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _CassetteScrew(),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: _CassetteScrew(),
                    ),
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: _CassetteScrew(),
                    ),

                    // Paper Cassette Label Sticker
                    Positioned(
                      top: 20,
                      left: 14,
                      right: 14,
                      bottom: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            // Top label header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white70,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'SIDE A',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'C-60',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Center Tape Window with Live Rotating Spools
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C0C10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black.withAlpha(200),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Left Spool (Supply Reel - shrinks as track plays)
                                  AnimatedBuilder(
                                    animation: _spoolRotationController,
                                    builder: (context, _) {
                                      return Transform.rotate(
                                        angle: _spoolRotationController.value *
                                            2 *
                                            math.pi,
                                        child: _LiveCassetteSpool(
                                          tapeRadius: 20 *
                                              (1.0 - (progress * 0.5)),
                                        ),
                                      );
                                    },
                                  ),

                                  // Center Tape Window with scale markings
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Magnetic tape ribbon bridge
                                      Container(
                                        width: 58,
                                        height: 10,
                                        color: const Color(0xFF382317),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '100 • 50 • 0',
                                        style: AppTypography.monoSmall.copyWith(
                                          fontSize: 7.5,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right Spool (Take-up Reel - grows as track plays)
                                  AnimatedBuilder(
                                    animation: _spoolRotationController,
                                    builder: (context, _) {
                                      return Transform.rotate(
                                        angle: _spoolRotationController.value *
                                            2 *
                                            math.pi,
                                        child: _LiveCassetteSpool(
                                          tapeRadius: 10 + (progress * 10),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Bottom info text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SPOOL LOW NOISE / HIGH OUTPUT',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 8,
                                  ),
                                ),
                                Text(
                                  'DOLBY NR',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Tape Head trapezoid window
                    Positioned(
                      bottom: 0,
                      left: 48,
                      right: 48,
                      height: 14,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF121216),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 8,
                              height: 6,
                              color: const Color(0xFF6B4A34),
                            ),
                            Container(
                              width: 14,
                              height: 6,
                              color: const Color(0xFF8B5A2B),
                            ),
                            Container(
                              width: 8,
                              height: 6,
                              color: const Color(0xFF6B4A34),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Live Time Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDuration(position),
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.neonOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    playbackState.isPlaying ? 'TAPE ROLLING' : 'PAUSED',
                    style: AppTypography.monoSmall.copyWith(
                      color: playbackState.isPlaying
                          ? AppColors.tapeGreen
                          : AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.formatDuration(duration),
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textMuted,
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

  /// Interactive mechanical transport bar at the bottom
  Widget _buildTransportBar({
    required dynamic playbackState,
    required dynamic settings,
    required AudioTrack track,
    required Duration position,
    required Duration duration,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F13),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrub Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: AppColors.neonOrange,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.parchment,
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble().clamp(
                    0.0,
                    duration.inMilliseconds.toDouble() > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                  ),
              max: duration.inMilliseconds.toDouble() > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              onChangeStart: (val) {
                setState(() {
                  _isDraggingSeek = true;
                  _dragSeekMs = val;
                });
              },
              onChanged: (val) {
                setState(() {
                  _dragSeekMs = val;
                });
              },
              onChangeEnd: (val) {
                _isDraggingSeek = false;
                ref
                    .read(playbackNotifierProvider.notifier)
                    .seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),

          // Playback Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous
              IconButton(
                iconSize: 26,
                tooltip: 'Previous Track',
                icon: const Icon(Icons.skip_previous, color: Colors.white70),
                onPressed: _skipPrev,
              ),

              // Rewind 10s
              IconButton(
                iconSize: 24,
                tooltip: 'Rewind 10s',
                icon: const Icon(Icons.fast_rewind, color: Colors.white70),
                onPressed: () {
                  MechanicalSoundService.instance.playMechanicalSound(
                    MechanicalSoundType.skipClick,
                    settings: settings,
                  );
                  final target = position - const Duration(seconds: 10);
                  ref.read(playbackNotifierProvider.notifier).seek(
                        target > Duration.zero ? target : Duration.zero,
                      );
                },
              ),

              // Play / Pause Primary Button
              GestureDetector(
                onTap: () {
                  ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.neonOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonOrange.withAlpha(160),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),

              // Fast Forward 10s
              IconButton(
                iconSize: 24,
                tooltip: 'Fast Forward 10s',
                icon: const Icon(Icons.fast_forward, color: Colors.white70),
                onPressed: () {
                  MechanicalSoundService.instance.playMechanicalSound(
                    MechanicalSoundType.skipClick,
                    settings: settings,
                  );
                  final target = position + const Duration(seconds: 10);
                  ref.read(playbackNotifierProvider.notifier).seek(
                        target < duration ? target : duration,
                      );
                },
              ),

              // Next
              IconButton(
                iconSize: 26,
                tooltip: 'Next Track',
                icon: const Icon(Icons.skip_next, color: Colors.white70),
                onPressed: _skipNext,
              ),

              // Add to Mixtape
              IconButton(
                iconSize: 22,
                tooltip: 'Record to Tape',
                icon: const Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.tapeAmber,
                ),
                onPressed: () {
                  AddToTapeModal.show(context, ref, track);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover(Color accent, AudioTrack track) {
    return Container(
      color: const Color(0xFF1D1E24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_outlined, size: 48, color: accent),
            const SizedBox(height: 8),
            Text(
              track.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoSmall.copyWith(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotating cassette spool with hub spokes and wound magnetic tape
class _LiveCassetteSpool extends StatelessWidget {
  final double tapeRadius;

  const _LiveCassetteSpool({required this.tapeRadius});

  @override
  Widget build(BuildContext context) {
    final clampedRadius = tapeRadius.clamp(8.0, 22.0);

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wound brown magnetic tape pancake
          Container(
            width: clampedRadius * 2,
            height: clampedRadius * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF452C1E),
            ),
          ),
          // White plastic hub ring with teeth
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E5EB),
              border: Border.all(color: const Color(0xFFB0B0BA), width: 1.5),
            ),
          ),
          // Center hole
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0C0C10),
            ),
          ),
          // 6 Cog teeth radiating from center
          for (int i = 0; i < 6; i++)
            Transform.rotate(
              angle: (i * 60) * math.pi / 180,
              child: Container(
                width: 2.2,
                height: 18,
                color: const Color(0xFF90909A),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tiny metallic screw in cassette corners
class _CassetteScrew extends StatelessWidget {
  const _CassetteScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF888890),
        border: Border.all(color: const Color(0xFF555560), width: 0.8),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 1,
          color: const Color(0xFF33333A),
        ),
      ),
    );
  }
}
