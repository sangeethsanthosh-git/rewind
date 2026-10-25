import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/audio_player/domain/audio_track.dart';
import '../../features/audio_player/domain/playback_state.dart';
import '../../features/audio_player/presentation/providers/audio_player_provider.dart';
import '../../features/audio_player/presentation/screens/now_playing_screen.dart';
import 'artwork_widget.dart';

class Song {
  final String title, artist, album;
  final Color strip, ink;
  final int art;
  final AudioTrack? audioTrack;
  final String? artworkPath;

  const Song(
    this.title,
    this.artist,
    this.album,
    this.strip,
    this.ink,
    this.art, {
    this.audioTrack,
    this.artworkPath,
  });

  factory Song.fromAudioTrack(AudioTrack track, int index) {
    const stripColors = <Color>[
      Color(0xFF1B2433),
      Color(0xFFF2F2F0),
      Color(0xFFD9582B),
      Color(0xFF2D4FB0),
      Color(0xFF171512),
      Color(0xFF7C97B4),
      Color(0xFF76A92E),
    ];
    const inks = <Color>[
      Colors.white,
      Color(0xFF111111),
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
      Color(0xFF0D1405),
    ];
    return Song(
      track.title,
      track.artist,
      track.album,
      stripColors[index % stripColors.length],
      inks[index % inks.length],
      index % 7,
      audioTrack: track,
      artworkPath: track.customArtPath,
    );
  }
}

const defaultSampleSongs = <Song>[
  Song('Come Together', 'The Beatles', 'Abbey Road', Color(0xFF1B2433), Colors.white, 0),
  Song('Pink + White', 'Frank Ocean', 'Blonde', Color(0xFFF2F2F0), Color(0xFF111111), 1),
  Song('Tití Me Preguntó', 'Bad Bunny', 'Un Verano Sin Ti', Color(0xFFD9582B), Colors.white, 2),
  Song('Taste', 'Sabrina Carpenter', 'Short n’ Sweet', Color(0xFF2D4FB0), Colors.white, 3),
  Song('Cry For Me', 'The Weeknd', 'Hurry Up Tomorrow', Color(0xFF171512), Colors.white, 4),
  Song('Wildest Dreams (Taylor’s Version)', 'Taylor Swift', '1989 (Taylor’s Version)',
      Color(0xFF7C97B4), Colors.white, 5),
  Song('360', 'Charli xcx', 'BRAT', Color(0xFF76A92E), Color(0xFF0D1405), 6),
];

class RealisticCassetteOpeningModal extends StatelessWidget {
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
    return Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, secAnim) => CassettePage(
        song: Song.fromAudioTrack(track, initialIndex),
        allTracks: allTracks,
      ),
      transitionsBuilder: (context, a, secAnim, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return CassettePage(
      song: Song.fromAudioTrack(track, initialIndex),
      allTracks: allTracks,
    );
  }
}

// ───────────────────────── Cassette page ─────────────────────────

class CassettePage extends ConsumerStatefulWidget {
  final Song song;
  final List<AudioTrack>? allTracks;

  const CassettePage({
    super.key,
    required this.song,
    this.allTracks,
  });

  @override
  ConsumerState<CassettePage> createState() => _CassettePageState();
}

class _CassettePageState extends ConsumerState<CassettePage> with TickerProviderStateMixin {
  static const double cw = 250, ch = 390; // case size
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _prog =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));
  bool playing = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _prog.addStatusListener((s) {
      if (s == AnimationStatus.completed) _setPlay(false);
    });

    if (widget.song.audioTrack != null) {
      final currentPlayback = ref.read(playbackNotifierProvider);
      if (currentPlayback.currentTrack?.id == widget.song.audioTrack!.id && currentPlayback.isPlaying) {
        playing = true;
        _spin.repeat();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(playbackNotifierProvider.notifier).playTrack(
                widget.song.audioTrack!,
                queue: widget.allTracks ?? [widget.song.audioTrack!],
              );
          setState(() => playing = true);
          _spin.repeat();
        });
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    _prog.dispose();
    super.dispose();
  }

  void _setPlay(bool p) {
    if (!mounted) return;
    setState(() => playing = p);
    if (p) {
      if (_prog.isCompleted) _prog.value = 0;
      _prog.forward();
      _spin.repeat();
      if (widget.song.audioTrack != null) {
        ref.read(playbackNotifierProvider.notifier).playTrack(
              widget.song.audioTrack!,
              queue: widget.allTracks ?? [widget.song.audioTrack!],
            );
      }
    } else {
      _prog.stop();
      _spin.stop();
      if (widget.song.audioTrack != null) {
        ref.read(playbackNotifierProvider.notifier).pause();
      }
    }
  }

  Future<void> _close() async {
    _setPlay(false);
    await _intro.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  String _fmt(double s) => '${s ~/ 60}:${(s % 60).floor().toString().padLeft(2, '0')}';

  double _seg(double a, double b, Curve c) =>
      c.transform(((_intro.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final playbackState = ref.watch(playbackNotifierProvider);
    final isTrackActive = widget.song.audioTrack != null &&
        playbackState.currentTrack?.id == widget.song.audioTrack!.id;
    final isAudioPlaying = isTrackActive ? playbackState.isPlaying : playing;

    if (isAudioPlaying && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!isAudioPlaying && _spin.isAnimating) {
      _spin.stop();
    }

    final double progressVal = (isTrackActive && playbackState.duration.inMilliseconds > 0)
        ? (playbackState.position.inMilliseconds / playbackState.duration.inMilliseconds).clamp(0.0, 1.0)
        : _prog.value;
    final Animation<double> cassetteProgress = isTrackActive
        ? AlwaysStoppedAnimation(progressVal)
        : _prog;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: LayoutBuilder(builder: (context, box) {
        final s = math.min(box.maxWidth * 0.92 / (2 * cw), (box.maxHeight - 270) / ch).clamp(0.5, 1.4);
        return Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [Colors.white.withAlpha(20), Colors.transparent]),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cw * s,
                    height: ch * s,
                    child: FittedBox(
                      child: SizedBox(
                        width: cw,
                        height: ch,
                        child: _buildCase(song, cassetteProgress),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _controls(playbackState, isTrackActive, isAudioPlaying, progressVal),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 8,
            child: SafeArea(
              child: IconButton(
                  onPressed: _close,
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xAA141416))),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildCase(Song song, Animation<double> cassetteProgress) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final rise = _seg(0, 0.3, Curves.easeOutCubic);
        final open = _seg(0.3, 0.72, Curves.easeInOutCubic);
        final lift = _seg(0.68, 1.0, Curves.easeOutCubic);
        final ang = -2.9 * open;

        final front = _CoverFront(song: song);
        final back = _CoverBack(song: song);

        final cover = Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(ang),
          child: ang.abs() < math.pi / 2
              ? front
              : Transform(
                  alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back),
        );

        final base = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C1C1F), Color(0xFF0B0B0C)]),
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40, offset: Offset(0, 28))],
          ),
        );

        final cassette = Center(
          child: Transform.scale(
            scale: 1 + 0.07 * lift,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha((150 * lift).round()),
                      blurRadius: 24,
                      offset: Offset(-14 * lift, 20 * lift)),
                ],
              ),
              child: CustomPaint(
                size: const Size(196, 326),
                painter: CassettePainter(song, _spin, cassetteProgress),
              ),
            ),
          ),
        );

        return Opacity(
          opacity: rise,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(125 * open, 180 * (1 - rise), 0)
              ..setEntry(3, 2, 0.0006)
              ..rotateX(0.96 * (1 - rise) + 0.1 * open)
              ..rotateY(-0.14 * open)
              ..scaleByDouble(0.6 + 0.4 * rise, 0.6 + 0.4 * rise, 1.0, 1.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [Positioned.fill(child: base), Positioned.fill(child: cassette), Positioned.fill(child: cover)],
            ),
          ),
        );
      },
    );
  }

  Widget _controls(
    SpoolPlaybackState playbackState,
    bool isTrackActive,
    bool isAudioPlaying,
    double progressVal,
  ) {
    const muted = Color(0xFF8A8A90);
    final String currentPosStr = (isTrackActive && playbackState.duration.inMilliseconds > 0)
        ? _fmt(playbackState.position.inSeconds.toDouble())
        : _fmt(_prog.value * 60);
    final String totalDurStr = (isTrackActive && playbackState.duration.inMilliseconds > 0)
        ? _fmt(playbackState.duration.inSeconds.toDouble())
        : '1:00';

    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final a = _seg(0.8, 1.0, Curves.easeOut);
        return Opacity(
          opacity: a,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - a)),
            child: SizedBox(
              width: math.min(MediaQuery.of(context).size.width * 0.88, 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(isAudioPlaying ? 'Playing' : 'Tap to play',
                    style: const TextStyle(color: muted, fontSize: 12, letterSpacing: 0.4)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    if (widget.song.audioTrack != null) {
                      if (isTrackActive) {
                        ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                      } else {
                        ref.read(playbackNotifierProvider.notifier).playTrack(
                              widget.song.audioTrack!,
                              queue: widget.allTracks ?? [widget.song.audioTrack!],
                            );
                      }
                    } else {
                      _setPlay(!playing);
                    }
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(isAudioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black, size: 32),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Text(currentPosStr, style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) {
                          final fraction = (d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0);
                          if (isTrackActive && playbackState.duration.inMilliseconds > 0) {
                            final seekMs = (fraction * playbackState.duration.inMilliseconds).round();
                            ref.read(playbackNotifierProvider.notifier).seek(Duration(milliseconds: seekMs));
                          } else {
                            _prog.value = fraction;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 4,
                                backgroundColor: const Color(0xFF2A2A2E),
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(totalDurStr, style: const TextStyle(color: muted, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCFCFD4),
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: const StadiumBorder()),
                  child: const Text('Full Player Deck', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _CoverFront extends StatelessWidget {
  final Song song;
  const _CoverFront({required this.song});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(fit: StackFit.expand, children: [
        _Art(song.art, artworkPath: song.artworkPath, audioTrack: song.audioTrack),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 14, 18, 12),
            decoration: BoxDecoration(color: song.strip, boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: song.ink,
                      fontSize: 20,
                      height: 1.1,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(song.artist, style: TextStyle(color: song.ink.withAlpha(220), fontSize: 12, letterSpacing: 0.4)),
            ]),
          ),
        ),
        // plastic hinge shading + gloss
        Positioned(
          left: 0, top: 0, bottom: 0, width: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.black.withAlpha(90), Colors.white.withAlpha(50), Colors.transparent]),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withAlpha(100), Colors.transparent, Colors.transparent, Colors.white.withAlpha(36)],
                stops: const [0, 0.3, 0.62, 1],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CoverBack extends StatelessWidget {
  final Song song;
  const _CoverBack({required this.song});
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3A2A1C), faint = Color(0xFF8A6A4A);
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(t.toUpperCase(),
            style: const TextStyle(color: faint, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2)));
    Widget body(String t) =>
        Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 13, height: 1.3, fontFamily: 'serif'));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6CF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 210,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: _Art(song.art, artworkPath: song.artworkPath, audioTrack: song.audioTrack),
              ),
            ),
            const SizedBox(height: 10),
            Text(song.album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ink, fontSize: 18, fontStyle: FontStyle.italic, fontFamily: 'serif')),
            label('Artist'),
            body(song.artist),
            const Divider(color: Color(0x553A2A1C), height: 18),
            label('Side A'),
            body('01  ${song.title}'),
            const Divider(color: Color(0x553A2A1C), height: 18),
            label('Side B'),
            body('Your own audio'),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Clear cassette painter ─────────────────────────

class CassettePainter extends CustomPainter {
  final Song song;
  final Animation<double> spin, progress;
  CassettePainter(this.song, this.spin, this.progress)
      : super(repaint: Listenable.merge([spin, progress]));

  void _text(Canvas c, String s, Offset o,
      {double size = 10,
      Color color = Colors.white,
      FontWeight w = FontWeight.normal,
      double rot = math.pi / 2,
      double maxW = double.infinity,
      String? font,
      FontStyle style = FontStyle.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(fontSize: size, color: color, fontWeight: w, fontFamily: font, fontStyle: style)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    tp.paint(c, Offset.zero);
    c.restore();
  }

  void _screw(Canvas c, Offset o, {bool ring = false}) {
    c.drawCircle(o, 7, Paint()..color = const Color(0xFF8A8D90));
    c.drawCircle(o, 6, Paint()..style = PaintingStyle.stroke..color = ring ? Colors.white70 : const Color(0xFF1D1D1D));
    if (!ring) {
      final p = Paint()..color = const Color(0xFF222222)..strokeWidth = 1.5;
      c.drawLine(o.translate(-4, 0), o.translate(4, 0), p);
      c.drawLine(o.translate(0, -4), o.translate(0, 4), p);
    }
  }

  void _spokes(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..color = Colors.white.withAlpha(60));
    final p = Paint()..color = Colors.white.withAlpha(210)..strokeWidth = 3;
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * r, p);
    }
    c.drawCircle(o, r, Paint()..style = PaintingStyle.stroke..color = Colors.white70);
  }

  void _reel(Canvas c, Offset o, double pack, double angle) {
    // tape pack: concentric layers
    c.drawCircle(o, pack, Paint()..shader = const RadialGradient(colors: [Color(0xFF3B2416), Color(0xFF25160C)]).createShader(Rect.fromCircle(center: o, radius: pack)));
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = const Color(0xFF120A05);
    for (var r = 34.0; r < pack; r += 2.4) {
      c.drawCircle(o, r, ring);
    }
    // hub
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    c.drawCircle(Offset.zero, 35, Paint()..color = Colors.black38);
    c.drawCircle(Offset.zero, 33, Paint()..color = const Color(0xFFE4E4E2));
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: 25);
    final teeth = Paint()..style = PaintingStyle.stroke..strokeWidth = 16..color = const Color(0xFF8E9296);
    for (var k = 0; k < 8; k++) {
      c.drawArc(ringRect, k * math.pi / 4 + 0.12, 0.28, false, teeth);
    }
    c.drawCircle(Offset.zero, 17, Paint()..shader = const RadialGradient(colors: [Color(0xFFC5C8CA), Color(0xFF8F9498)]).createShader(Rect.fromCircle(center: Offset.zero, radius: 17)));
    c.drawCircle(Offset.zero, 17, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFE6E6E4));
    c.drawArc(Rect.fromCircle(center: Offset.zero, radius: 27), math.pi * 0.85, 0.7, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = const Color(0xFFB3122B));
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) {
    final full = Offset.zero & s;
    final shell = RRect.fromRectAndRadius(full, const Radius.circular(9));
    c.drawRRect(
        shell,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE4E8EA), Color(0xFFAAB0B4), Color(0xFFC9CFD2), Color(0xFF9DA3A7)],
                  stops: [0, 0.38, 0.7, 1])
              .createShader(full));
    c.drawRRect(shell.deflate(1), Paint()..style = PaintingStyle.stroke..color = Colors.white70);

    // grey window pane
    final pane = RRect.fromLTRBR(57, 16, s.width - 4, s.height - 16, const Radius.circular(4));
    c.drawRRect(
        pane,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF4F5255), Color(0xFF7B7F82), Color(0xFFA2A6A8), Color(0xFF8D9194)],
                  stops: [0, 0.24, 0.52, 1])
              .createShader(pane.outerRect));
    c.drawRRect(pane, Paint()..style = PaintingStyle.stroke..color = Colors.white30);

    // clear head bracket (left)
    final hd = RRect.fromLTRBR(5, s.height * .17, 53, s.height * .84, const Radius.circular(5));
    c.drawRRect(hd, Paint()..color = Colors.white.withAlpha(75));
    c.drawRRect(hd, Paint()..style = PaintingStyle.stroke..color = Colors.white.withAlpha(170));
    final hole = Paint()..color = Colors.black.withAlpha(115);
    for (final y in [hd.top + 17, hd.bottom - 17]) {
      c.drawCircle(Offset(29, y), 6.5, hole);
      c.drawCircle(Offset(29, y), 7.5, Paint()..style = PaintingStyle.stroke..color = Colors.white70);
    }
    for (final f in [.3, .68]) {
      c.drawRect(Rect.fromCenter(center: Offset(29, hd.top + hd.height * f), width: 14, height: 14), hole);
    }
    _spokes(c, const Offset(22, 22), 15);
    _spokes(c, Offset(22, s.height - 24), 15);

    // printed text
    _text(c, 'RMA. POS/PE I NORMAL POSITION', const Offset(71, 24), size: 6.2);
    _text(c, 'BIAS 120 µs RMAL BIAS 120 µs EQ', const Offset(64, 24), size: 6.2);
    _text(c, 'C-60', const Offset(85, 156), size: 25, w: FontWeight.w700);
    _text(c, 'LOW NOISE', const Offset(80, 221), size: 11);
    final guide = Paint()..color = Colors.white.withAlpha(150)..strokeWidth = 1;
    for (var y = 168.0; y < 226; y += 7) {
      c.drawLine(Offset(87, y), Offset(133, y), guide);
    }

    // reels + tape run
    final p = progress.value, ang = spin.value * 2 * math.pi;
    c.drawLine(const Offset(79, 166), const Offset(155, 225),
        Paint()..strokeWidth = 2..color = const Color(0xBF3C3028));
    _reel(c, const Offset(115, 101), 67 * (1 - .45 * p), ang);
    _reel(c, const Offset(115, 241), 67 * (.55 + .45 * p), ang);

    // paper label
    final lab = RRect.fromLTRBR(151, 36, 187, 306, const Radius.circular(2));
    c.drawShadow(Path()..addRRect(lab), Colors.black, 3, true);
    c.drawRRect(lab, Paint()..color = const Color(0xFFF0E8D1));
    c.drawCircle(const Offset(158, 90), 28, Paint()..color = const Color(0x20BE9F6E));
    c.drawCircle(const Offset(180, 270), 30, Paint()..color = const Color(0x1EBE9F6E));
    final a = TextPainter(
        text: const TextSpan(text: 'A', style: TextStyle(color: Color(0xFFC1202F), fontSize: 20, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr)
      ..layout();
    a.paint(c, Offset(169 - a.width / 2, 40));
    c.drawLine(const Offset(156, 68), const Offset(182, 68), Paint()..color = const Color(0xFF333333)..strokeWidth = 1);
    final fs = (250 / (song.title.length * .62)).clamp(9.0, 18.0).toDouble();
    _text(c, song.title, Offset(169 + fs * .6, 74),
        size: fs, color: const Color(0xFF17171F), w: FontWeight.w700, maxW: 200, font: 'cursive', style: FontStyle.italic);
    _text(c, 'NR [ ]  ▢IN ▢OUT', const Offset(172, 288), size: 5.5, color: const Color(0xFF222222));

    // screws
    _screw(c, const Offset(13, 12));
    _screw(c, Offset(s.width - 14, 15), ring: true);
    _screw(c, Offset(15, s.height - 12));
    _screw(c, const Offset(39, 167));

    // gloss + scratches
    c.drawRRect(
        shell,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withAlpha(100), Colors.transparent, Colors.transparent, Colors.white.withAlpha(56)],
                  stops: const [0, .24, .68, 1])
              .createShader(full));
    final sc = Paint()..color = Colors.white.withAlpha(46)..strokeWidth = .6;
    c.drawLine(const Offset(20, 250), const Offset(120, 40), sc);
    c.drawLine(const Offset(70, 320), const Offset(190, 180), sc);
    c.drawLine(const Offset(100, 20), const Offset(150, 110), sc);
  }

  @override
  bool shouldRepaint(covariant CassettePainter old) => old.song != song;
}

/// Abstract artwork (falls back to gradient/radial blobs or real album artwork if available)
class _Art extends StatelessWidget {
  final int kind;
  final String? artworkPath;
  final AudioTrack? audioTrack;

  const _Art(this.kind, {this.artworkPath, this.audioTrack});

  Widget _blob(Alignment c, double r, Color col) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
                center: c, radius: r, colors: [col, col.withAlpha(0)], stops: const [0.55, 1.0]),
          ),
        ),
      );

  Widget _grad(List<Color> colors,
          {Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter}) =>
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: begin, end: end, colors: colors)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (artworkPath != null && artworkPath!.isNotEmpty && File(artworkPath!).existsSync()) {
      return Image.file(
        File(artworkPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackArt(),
      );
    }
    if (audioTrack != null) {
      return ArtworkWidget(
        id: audioTrack!.albumId ?? int.tryParse(audioTrack!.id),
        albumId: audioTrack!.albumId,
        customArtPath: audioTrack!.customArtPath,
        title: audioTrack!.title,
        artist: audioTrack!.artist,
        size: double.infinity,
        borderRadius: 0,
      );
    }
    return _buildFallbackArt();
  }

  Widget _buildFallbackArt() {
    final List<Widget> layers;
    switch (kind) {
      case 0:
        layers = [
          _grad(const [Color(0xFF9AB6CC), Color(0xFF2B3C4A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          _blob(const Alignment(0.55, -0.4), 0.75, const Color(0xFF2F5A3A)),
          _blob(const Alignment(-0.6, 0.4), 0.6, const Color(0xFF6B7F8C)),
        ];
        break;
      case 1:
        layers = [
          Positioned.fill(child: Container(color: const Color(0xFFE6E6E3))),
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: 0.64,
              heightFactor: 0.6,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8A6A52), Color(0xFF3F2F26)]),
                ),
              ),
            ),
          ),
        ];
        break;
      case 2:
        layers = [
          Positioned.fill(child: Container(color: const Color(0xFFFF6A2B))),
          _blob(const Alignment(-0.5, -0.4), 0.55, const Color(0xFFFFD23F)),
          _blob(const Alignment(0.55, -0.3), 0.6, const Color(0xFFFF8FB1)),
          _blob(const Alignment(0.0, 1.0), 0.8, const Color(0xFF4CC06A)),
        ];
        break;
      case 3:
        layers = [
          _grad(const [Color(0xFF233F95), Color(0xFF1A2A6A)]),
          _blob(const Alignment(0.0, 1.1), 0.9, const Color(0xFFE8903A)),
        ];
        break;
      case 4:
        layers = [
          _grad(const [Color(0xFF0D0B0A), Color(0xFF1B1612)]),
          _blob(const Alignment(0.0, -1.1), 0.9, const Color(0xFFB8651F)),
        ];
        break;
      case 5:
        layers = [
          _grad(const [Color(0xFFCFE3F2), Color(0xFF7FA8C9)],
              begin: Alignment.topRight, end: Alignment.bottomLeft),
          _blob(const Alignment(0.4, -0.2), 0.5, const Color(0xFFF2B6A0)),
        ];
        break;
      default:
        layers = [_grad(const [Color(0xFF8CC63F), Color(0xFF6FA82A)])];
    }
    return Stack(children: layers);
  }
}
