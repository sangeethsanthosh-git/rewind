import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/mechanical_sound_service.dart';
import '../../../../core/widgets/artwork_widget.dart';
import '../../../audio_player/domain/audio_track.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../audio_player/presentation/screens/now_playing_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Responsive 3D Song Stack with acrylic cassette jewel box aesthetics,
/// immediate playback response, and authentic retro mechanical interactions.
class ResponsiveSongStack extends ConsumerStatefulWidget {
  final List<AudioTrack> tracks;
  final Function(AudioTrack track)? onTrackTap;

  const ResponsiveSongStack({
    super.key,
    required this.tracks,
    this.onTrackTap,
  });

  @override
  ConsumerState<ResponsiveSongStack> createState() => _ResponsiveSongStackState();
}

class _ResponsiveSongStackState extends ConsumerState<ResponsiveSongStack> {
  static const double perSong = 240;
  static const double perspective = 900;
  static const double slabThickness = 34;
  static const int startIndex = 0;

  late final ScrollController _controller;
  int _lastSnappedIndex = startIndex;

  @override
  void initState() {
    super.initState();
    _lastSnappedIndex = startIndex;
    _controller = ScrollController(initialScrollOffset: startIndex * perSong);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snap() {
    if (!_controller.hasClients) return;
    final effectiveTracks = widget.tracks.isNotEmpty ? widget.tracks : _getSampleTracks();
    final nearest = (_controller.offset / perSong).round().clamp(0, effectiveTracks.length - 1);
    final goal = nearest * perSong;

    if ((_controller.offset - goal).abs() > 1) {
      _controller.animateTo(
        goal,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }

    if (_lastSnappedIndex != nearest) {
      _lastSnappedIndex = nearest;
      HapticFeedback.selectionClick();
      MechanicalSoundService.instance.playMechanicalSound(
        MechanicalSoundType.skipClick,
        settings: ref.read(settingsNotifierProvider),
      );
    }
  }

  void _scrollToIndex(int index) {
    if (!_controller.hasClients) return;
    final effectiveTracks = widget.tracks.isNotEmpty ? widget.tracks : _getSampleTracks();
    final goal = (index * perSong).clamp(0.0, (effectiveTracks.length - 1) * perSong);
    _controller.animateTo(
      goal,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _tap(double dy, double h, double gap, double eyeLevelY, List<AudioTrack> tracks) {
    final pos = _controller.hasClients ? _controller.offset / perSong : 0.0;
    int best = 0;
    double bestD = 1e9;

    for (var i = 0; i < tracks.length; i++) {
      final cardY = (i - pos) * gap + eyeLevelY;
      final d = (cardY - dy).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }

    // Require tap to be within proximity of the card
    if (bestD > gap * 0.9) return;
    _handleTrackTap(best, tracks[best], tracks);
  }

  void _handleTrackTap(int index, AudioTrack track, List<AudioTrack> tracks) {
    _scrollToIndex(index);
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.doorLatch,
      settings: ref.read(settingsNotifierProvider),
    );
    HapticFeedback.mediumImpact();

    if (widget.onTrackTap != null) {
      widget.onTrackTap!(track);
    } else {
      ref.read(playbackNotifierProvider.notifier).playTrack(
        track,
        queue: tracks,
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTracks = widget.tracks.isNotEmpty ? widget.tracks : _getSampleTracks();
    final playbackState = ref.watch(playbackNotifierProvider);
    final hasActiveTrack = playbackState.currentTrack != null;

    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth * 0.86, 540.0);
        final d = w * 0.74;
        final gap = math.max(90.0, box.maxHeight * 0.165);
        // Position eye-level in the upper-third below header so cards fill from top to bottom
        final eyeLevelY = box.maxHeight * 0.38;

        return Stack(
          children: [
            // 3D Scene of floating cassette slabs
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final pos = _controller.hasClients
                        ? _controller.offset / perSong
                        : (_lastSnappedIndex.toDouble());

                    return ClipRect(
                      child: Stack(
                        children: _buildCards(
                          pos: pos,
                          w: w,
                          d: d,
                          gap: gap,
                          eyeLevelY: eyeLevelY,
                          boxHeight: box.maxHeight,
                          tracks: effectiveTracks,
                          playbackState: playbackState,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Scroll View handling gestures & driving the 3D stack
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (t) => _tap(t.localPosition.dy, box.maxHeight, gap, eyeLevelY, effectiveTracks),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      Future.microtask(_snap);
                    }
                    return false;
                  },
                  child: ListView(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      SizedBox(
                        height: (effectiveTracks.length - 1) * perSong + box.maxHeight,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Retro Hi-Fi Stack HUD (Positioned above floating now-playing banner)
            _Hud(
              controller: _controller,
              tracks: effectiveTracks,
              hasActiveTrack: hasActiveTrack,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCards({
    required double pos,
    required double w,
    required double d,
    required double gap,
    required double eyeLevelY,
    required double boxHeight,
    required List<AudioTrack> tracks,
    required dynamic playbackState,
  }) {
    final n = tracks.length;
    // Painter's algorithm: sort farthest from eye level first
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) => (b - pos).abs().compareTo((a - pos).abs()));

    final out = <Widget>[];

    for (final i in order) {
      final delta = i - pos;
      final a = delta.abs();
      if (a > 5.2) continue;

      final y = delta * gap;
      final opacity = a < 3.6 ? 1.0 : (1.0 - (a - 3.6) / 1.4).clamp(0.0, 1.0);
      final track = tracks[i];
      final isPlaying = playbackState.currentTrack?.id == track.id && playbackState.isPlaying;
      final spineColor = AppColors.spinePalette[i % AppColors.spinePalette.length];

      // Base 3D transformation matrix anchored at eyeLevelY
      Matrix4 base() => Matrix4.identity()
        ..setEntry(3, 2, -1 / perspective)
        ..multiply(Matrix4.translationValues(0.0, y + (eyeLevelY - boxHeight / 2), 0.0));

      final faces = <Widget>[];

      // Top Art Face: visible when slab is below eye level
      if (y > slabThickness / 2) {
        faces.add(_face(
          base()
            ..rotateX(math.pi / 2)
            ..multiply(Matrix4.translationValues(0.0, 0.0, slabThickness / 2)),
          w,
          d,
          _ArtFace(track: track, w: w, d: d),
        ));
      }
      // Underside Face: visible when slab is above eye level
      else if (y < -slabThickness / 2) {
        faces.add(_face(
          base()
            ..rotateX(-math.pi / 2)
            ..multiply(Matrix4.translationValues(0.0, 0.0, slabThickness / 2)),
          w,
          d,
          _ArtFace(track: track, w: w, d: d),
        ));
      }

      // Front Label Strip on the near edge facing the listener (always visible)
      faces.add(_face(
        base()..multiply(Matrix4.translationValues(0.0, 0.0, d / 2)),
        w,
        slabThickness,
        _Strip(
          track: track,
          spineColor: spineColor,
          isPlaying: isPlaying,
          thickness: slabThickness,
        ),
      ));

      out.add(Positioned.fill(
        child: Opacity(
          opacity: opacity,
          child: Stack(fit: StackFit.expand, children: faces),
        ),
      ));
    }

    return out;
  }

  Widget _face(Matrix4 m, double w, double h, Widget child) {
    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: Center(
        child: SizedBox(
          width: w,
          height: h,
          child: child,
        ),
      ),
    );
  }

  List<AudioTrack> _getSampleTracks() {
    return [
      const AudioTrack(
        id: 'sample_bad_eyes',
        title: 'Bad Eyes Villain Theme',
        artist: 'Anirudh Ravichander',
        album: 'Kaththi (Original Motion Picture Soundtrack)',
        durationMs: 90000,
        uri: '',
        path: '',
        fileExtension: 'flac',
        isLossless: true,
        bitDepth: 24,
        sampleRate: 96000,
      ),
      const AudioTrack(
        id: 'sample_kaththi',
        title: 'Kaththi Theme The Sword of Destiny',
        artist: 'Anirudh Ravichander',
        album: 'Kaththi (Original Motion Picture Soundtrack)',
        durationMs: 75000,
        uri: '',
        path: '',
        fileExtension: 'flac',
        isLossless: true,
        bitDepth: 24,
        sampleRate: 96000,
      ),
      const AudioTrack(
        id: 'sample_come_together',
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        durationMs: 259000,
        uri: '',
        path: '',
        fileExtension: 'flac',
        isLossless: true,
        bitDepth: 24,
      ),
      const AudioTrack(
        id: 'sample_pink_white',
        title: 'Pink + White',
        artist: 'Frank Ocean',
        album: 'Blonde',
        durationMs: 184000,
        uri: '',
        path: '',
        fileExtension: 'm4a',
      ),
      const AudioTrack(
        id: 'sample_wildest_dreams',
        title: "Wildest Dreams (Taylor's Version)",
        artist: 'Taylor Swift',
        album: '1989 (Taylor\'s Version)',
        durationMs: 220000,
        uri: '',
        path: '',
        fileExtension: 'flac',
        isLossless: true,
      ),
    ];
  }
}

/// Front Label Strip on the near edge with vintage typography and codec badge
class _Strip extends StatelessWidget {
  final AudioTrack track;
  final Color spineColor;
  final bool isPlaying;
  final double thickness;

  const _Strip({
    required this.track,
    required this.spineColor,
    required this.isPlaying,
    required this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = spineColor.computeLuminance() < 0.45;
    final textColor = isDark ? Colors.white : const Color(0xFF111114);

    return Container(
      height: thickness,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: spineColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withAlpha(50), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isPlaying) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: AppColors.neonOrange, size: 12),
            ),
          ],
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  fontFamily: 'Courier',
                ),
                children: [
                  TextSpan(
                    text: '${track.title}  ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: track.artist,
                    style: TextStyle(
                      color: textColor.withAlpha(200),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: textColor.withAlpha(80), width: 0.5),
            ),
            child: Text(
              track.fileExtension.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real Music Banner Artwork Face styled like a clear acrylic Cassette Jewel Box with J-card insert
class _ArtFace extends StatelessWidget {
  final AudioTrack track;
  final double w;
  final double d;

  const _ArtFace({
    required this.track,
    required this.w,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    final hash = track.title.hashCode.abs();
    final accent = AppColors.spinePalette[hash % AppColors.spinePalette.length];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(220),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // J-Card Paper Inset Background
            Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8DC),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFD6C8B4), width: 1.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Actual Music Banner Image
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 48, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: (track.customArtPath != null &&
                              track.customArtPath!.isNotEmpty &&
                              File(track.customArtPath!).existsSync())
                          ? Image.file(
                              File(track.customArtPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(accent),
                            )
                          : (track.albumId != null
                              ? ArtworkWidget(
                                  id: track.albumId,
                                  size: double.infinity,
                                  borderRadius: 0,
                                  title: track.title,
                                  artist: track.artist,
                                )
                              : _buildPlaceholder(accent)),
                    ),
                  ),

                  // Right J-Card Folded Flap
                  Positioned(
                    top: 8,
                    right: 8,
                    bottom: 8,
                    width: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'A',
                            style: AppTypography.monoSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              'C-60 STEREO',
                              maxLines: 1,
                              style: AppTypography.monoSmall.copyWith(
                                color: Colors.white70,
                                fontSize: 7.5,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Acrylic Jewel Box Bevel & Glare Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha(45),
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Acrylic Hinge Knuckles on the right edge
            Positioned(
              right: 6,
              top: 12,
              child: _AcrylicHingeBump(),
            ),
            Positioned(
              right: 6,
              bottom: 12,
              child: _AcrylicHingeBump(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accent) {
    return Container(
      color: const Color(0xFF1E1F24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(30),
              border: Border.all(color: accent.withAlpha(100), width: 2),
            ),
            child: Center(
              child: Icon(Icons.album_outlined, size: 40, color: accent),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Text(
              track.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.monoSmall.copyWith(color: Colors.white70, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small clear acrylic hinge knuckle on the cassette case edge
class _AcrylicHingeBump extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0x60FFFFFF),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0x90FFFFFF), width: 0.8),
      ),
    );
  }
}

/// Retro Hi-Fi Stack HUD from song_stack (1).dart
class _Hud extends StatelessWidget {
  final ScrollController controller;
  final List<AudioTrack> tracks;
  final bool hasActiveTrack;

  const _Hud({
    required this.controller,
    required this.tracks,
    required this.hasActiveTrack,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    // Dynamically position above Now Playing banner on home screen
    final bottomPadding = hasActiveTrack ? 144.0 : 12.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final pos = controller.hasClients
                  ? controller.offset / _ResponsiveSongStackState.perSong
                  : 0.0;
              final idx = pos.round().clamp(0, tracks.length - 1);
              final track = tracks[idx];
              const muted = Color(0xFF8A8A90);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${idx + 1} / ${tracks.length}',
                      style: const TextStyle(
                        color: AppColors.neonOrange,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '${track.title} ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '• ${track.artist}',
                            style: const TextStyle(color: muted),
                          ),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SCROLL',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
