import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../services/mechanical_sound_service.dart';
import '../../features/audio_player/domain/audio_track.dart';
import '../../features/library/domain/folder_model.dart';
import '../../features/settings/domain/app_settings.dart';
import 'artwork_widget.dart';

class EuropeDeluxeDisc extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? description;
  final List<FolderModel>? folders;
  final Function(FolderModel folder)? onFolderTap;
  final List<AudioTrack>? tracks;
  final Function(AudioTrack track)? onTrackTap;
  final String? activeTrackId;
  final AppSettings? settings;

  const EuropeDeluxeDisc({
    super.key,
    required this.title,
    this.subtitle = 'Spool Analog Stereo',
    this.description,
    this.folders,
    this.onFolderTap,
    this.tracks,
    this.onTrackTap,
    this.activeTrackId,
    this.settings,
  });

  @override
  State<EuropeDeluxeDisc> createState() => _EuropeDeluxeDiscState();
}

class _EuropeDeluxeDiscState extends State<EuropeDeluxeDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController.unbounded(vsync: this);

  double _lastAngle = 0;
  Offset _lastPos = Offset.zero;
  int _bgSceneIndex = 0;
  String? _customBackdropPath;

  bool get isFolderMode => widget.folders != null && widget.folders!.isNotEmpty;
  int get itemCount => isFolderMode ? widget.folders!.length : (widget.tracks?.length ?? 0);

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  double _angleAt(Offset p, Offset center) =>
      math.atan2(p.dy - center.dy, p.dx - center.dx);

  void _panStart(DragStartDetails d, Offset center) {
    _spin.stop();
    _lastAngle = _angleAt(d.localPosition, center);
    _lastPos = d.localPosition;
  }

  void _panUpdate(DragUpdateDetails d, Offset center) {
    final a = _angleAt(d.localPosition, center);
    var da = a - _lastAngle;
    if (da > math.pi) da -= 2 * math.pi;
    if (da < -math.pi) da += 2 * math.pi;
    _spin.value += da;
    _lastAngle = a;
    _lastPos = d.localPosition;
  }

  void _panEnd(DragEndDetails d, Offset center) {
    final p = _lastPos - center;
    final v = d.velocity.pixelsPerSecond;
    final r2 = p.dx * p.dx + p.dy * p.dy;
    if (r2 < 1) return;
    final omega = (p.dx * v.dy - p.dy * v.dx) / r2;
    if (omega.abs() < 0.3) return;
    _spin.animateWith(FrictionSimulation(0.135, _spin.value, omega));
  }

  void _turn(double radians) {
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: widget.settings ?? const AppSettings(),
    );
    _spin.animateTo(
      _spin.value + radians,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _resetSpin() {
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: widget.settings ?? const AppSettings(),
    );
    final target = (_spin.value / (2 * math.pi)).round() * 2 * math.pi;
    _spin.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  int _calculateActiveIndex() {
    if (itemCount <= 0) return 0;
    // 12 windows around the disc (30 degrees each)
    const step = 2 * math.pi / 12;
    final rawIndex = (-_spin.value / step).round();
    return ((rawIndex % itemCount) + itemCount) % itemCount;
  }

  AudioTrack? _getRepresentativeTrack(FolderModel? folder) {
    if (folder == null || folder.tracks.isEmpty) return null;
    return folder.tracks.firstWhere(
      (t) => t.customArtPath != null && t.customArtPath!.isNotEmpty && File(t.customArtPath!).existsSync(),
      orElse: () => folder.tracks.firstWhere(
        (t) => t.albumId != null,
        orElse: () => folder.tracks.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        final activeIdx = _calculateActiveIndex();
        final FolderModel? activeFolder =
            isFolderMode && activeIdx < widget.folders!.length ? widget.folders![activeIdx] : null;
        final AudioTrack? activeTrack = !isFolderMode && widget.tracks != null && activeIdx < widget.tracks!.length
            ? widget.tracks![activeIdx]
            : (activeFolder != null ? _getRepresentativeTrack(activeFolder) : null);

        return LayoutBuilder(builder: (context, box) {
          final accentColor = Theme.of(context).primaryColor;
          final size = box.biggest;
          final center = Offset(size.width / 2, size.height / 2);
          final d = math.min(
            math.min(size.width * 0.94, size.height * 0.76),
            580.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Scenic Photographic / Image Backdrops (Instead of just changing solid colors)
              _buildScenicBackdrop(activeTrack),

              // Top Active Reel Info HUD Banner
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xDC14141A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(160),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Folder / Track Icon Badge
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor.withAlpha(120), width: 0.8),
                          ),
                          child: Icon(
                            isFolderMode ? Icons.folder_rounded : Icons.album_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isFolderMode
                                    ? (activeFolder?.name.toUpperCase() ?? widget.title)
                                    : (activeTrack?.title ?? widget.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                isFolderMode
                                    ? '${activeFolder?.trackCount ?? 0} TRACKS â€¢ ${activeIdx + 1} OF $itemCount FOLDERS'
                                    : (activeTrack?.artist ?? widget.subtitle),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monoSmall.copyWith(
                                  color: AppColors.tapeAmber,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (activeFolder != null) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: accentColor.withAlpha(40),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: accentColor, width: 1.0),
                              ),
                            ),
                            icon: Icon(Icons.folder_open_rounded, size: 14, color: accentColor),
                            label: Text(
                              'OPEN',
                              style: AppTypography.monoSmall.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            onPressed: () {
                              MechanicalSoundService.instance.playMechanicalSound(
                                MechanicalSoundType.cassetteInsert,
                                settings: widget.settings ?? const AppSettings(),
                              );
                              widget.onFolderTap?.call(activeFolder);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive Rotating View-Master Disc
              Listener(
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) {
                    _spin.stop();
                    _spin.value += e.scrollDelta.dy * 0.003;
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (e) => _panStart(e, center),
                  onPanUpdate: (e) => _panUpdate(e, center),
                  onPanEnd: (e) => _panEnd(e, center),
                  child: Center(
                    child: Transform.rotate(
                      angle: _spin.value,
                      child: SizedBox(
                        width: d,
                        height: d,
                        child: _DiscLayout(
                          size: d,
                          title: widget.title,
                          subtitle: widget.subtitle,
                          description: widget.description,
                          folders: widget.folders,
                          tracks: widget.tracks,
                          activeTrackId: widget.activeTrackId,
                          onTapFolder: (folder) {
                            MechanicalSoundService.instance.playMechanicalSound(
                              MechanicalSoundType.cassetteInsert,
                              settings: widget.settings ?? const AppSettings(),
                            );
                            widget.onFolderTap?.call(folder);
                          },
                          onTapTrack: (track) {
                            MechanicalSoundService.instance.playMechanicalSound(
                              MechanicalSoundType.cassetteInsert,
                              settings: widget.settings ?? const AppSettings(),
                            );
                            widget.onTrackTap?.call(track);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Floating Controls & Scenic Backdrop Switcher Dock
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xEB141218),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(180),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Spin Left',
                              icon: const Icon(Icons.rotate_left, color: Colors.white70),
                              onPressed: () => _turn(-math.pi / 6),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              onPressed: _resetSpin,
                              child: const Text('RESET',
                                  style: TextStyle(
                                      color: AppColors.tapeAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Spin Right',
                              icon: const Icon(Icons.rotate_right, color: Colors.white70),
                              onPressed: () => _turn(math.pi / 6),
                            ),
                            Container(
                              width: 1,
                              height: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              color: Colors.white24,
                            ),
                            // Scenic Image Switcher Button
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Change Scenic Backdrop Image',
                              icon: Icon(Icons.wallpaper_rounded, color: accentColor),
                              onPressed: _cycleBackdropScene,
                            ),
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Pick Custom Wallpaper Image',
                              icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70),
                              onPressed: _pickCustomWallpaper,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _cycleBackdropScene() {
    MechanicalSoundService.instance.playMechanicalSound(
      MechanicalSoundType.skipClick,
      settings: widget.settings ?? const AppSettings(),
    );
    setState(() {
      _bgSceneIndex = (_bgSceneIndex + 1) % 4;
      _customBackdropPath = null;
    });
    final titles = [
      'Ambient Folder Artwork',
      'Amsterdam Canal 1970s',
      'Tokyo 1984 Studio Night',
      'Audiophile Hi-Fi Walnut Deck',
    ];
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backdrop Image: ${titles[_bgSceneIndex]}'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _pickCustomWallpaper() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isNotEmpty && files.first.path != null) {
      setState(() {
        _customBackdropPath = files.first.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom backdrop wallpaper applied!')),
        );
      }
    }
  }

  Widget _buildScenicBackdrop(AudioTrack? repTrack) {
    if (_customBackdropPath != null && File(_customBackdropPath!).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_customBackdropPath!), fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(160)),
        ],
      );
    }

    switch (_bgSceneIndex) {
      case 0:
        // Dynamic Ambient Folder/Song Artwork Blur
        final customPath = repTrack?.customArtPath;
        if (customPath != null && customPath.isNotEmpty && File(customPath).existsSync()) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(customPath), fit: BoxFit.cover),
              ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(200),
                          Colors.black.withAlpha(140),
                          Colors.black.withAlpha(220),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2222), Color(0xFF0F1416), Color(0xFF161A22)],
            ),
          ),
          child: const Opacity(opacity: 0.4, child: CustomPaint(painter: _CanalScenePainter())),
        );

      case 1:
        // Amsterdam Canal Film Scene
        return Container(
          color: const Color(0xFF1E2625),
          child: const Opacity(opacity: 0.5, child: CustomPaint(painter: _CanalScenePainter())),
        );

      case 2:
        // Tokyo 1984 Analog Studio Night
        return Container(
          color: const Color(0xFF140D18),
          child: const Opacity(opacity: 0.45, child: CustomPaint(painter: _TokyoStudioScenePainter())),
        );

      case 3:
      default:
        // Audiophile Hi-Fi Walnut Lounge
        return Container(
          color: const Color(0xFF1A130E),
          child: const Opacity(opacity: 0.5, child: CustomPaint(painter: _WalnutLoungeScenePainter())),
        );
    }
  }
}

class _DiscLayout extends StatelessWidget {
  final double size;
  final String title;
  final String subtitle;
  final String? description;
  final List<FolderModel>? folders;
  final List<AudioTrack>? tracks;
  final String? activeTrackId;
  final Function(FolderModel folder)? onTapFolder;
  final Function(AudioTrack track)? onTapTrack;

  const _DiscLayout({
    required this.size,
    required this.title,
    required this.subtitle,
    this.description,
    this.folders,
    this.tracks,
    required this.activeTrackId,
    this.onTapFolder,
    this.onTapTrack,
  });

  static const double winSize = 92;
  static const double winRadius = 240;

  @override
  Widget build(BuildContext context) {
    final u = size / 700;
    final w = winSize * u;
    final isFolderMode = folders != null && folders!.isNotEmpty;
    final count = isFolderMode ? folders!.length : (tracks?.length ?? 0);

    return Stack(
      children: [
        // The View-Master Painted Paper Disc
        Positioned.fill(
          child: CustomPaint(
            painter: _EuropeDiscPainter(
              title: title,
              subtitle: subtitle,
              description: description,
              trackCount: count,
            ),
          ),
        ),

        // 12 Radial Windows around the perimeter
        for (var k = 0; k < 12; k++) ...[
          Positioned.fill(
            child: Transform.rotate(
              angle: (15 + 30 * k) * math.pi / 180,
              child: Stack(
                children: [
                  Positioned(
                    left: size / 2 - w / 2,
                    top: size / 2 - winRadius * u - w / 2,
                    width: w,
                    height: w,
                    child: _DiscWindow(
                      index: k,
                      radius: 16 * u,
                      folder: isFolderMode && k < folders!.length ? folders![k] : null,
                      track: !isFolderMode && tracks != null && k < tracks!.length ? tracks![k] : null,
                      isActive: !isFolderMode && tracks != null && k < tracks!.length && tracks![k].id == activeTrackId,
                      onTap: () {
                        if (isFolderMode && k < folders!.length) {
                          onTapFolder?.call(folders![k]);
                        } else if (!isFolderMode && tracks != null && k < tracks!.length) {
                          onTapTrack?.call(tracks![k]);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiscWindow extends StatelessWidget {
  final int index;
  final double radius;
  final FolderModel? folder;
  final AudioTrack? track;
  final bool isActive;
  final VoidCallback onTap;

  const _DiscWindow({
    required this.index,
    required this.radius,
    this.folder,
    this.track,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final accentColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(
            color: isActive ? accentColor : const Color(0x66000000),
            width: isActive ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accentColor.withAlpha(160),
                blurRadius: 10,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (folder != null) ...[
                // Folder Image (From customArtPath or album artwork)
                _buildFolderArtwork(context, folder!),
              ] else if (track != null) ...[
                // Track Image
                _buildTrackArtwork(context, track!),
              ] else ...[
                // Empty Window with stylized vintage graphic
                CustomPaint(painter: _EmptyWindowPainter(index)),
              ],

              // Inner lens vignette gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.75,
                    colors: [Color(0x00000000), Color(0x55000000)],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),

              // Window sequence number badge (Top-Left)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Folder Badge or Track Format Badge (Top-Right)
              if (folder != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.tapeAmber.withAlpha(120), width: 0.8),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: AppColors.tapeAmber,
                      size: 10,
                    ),
                  ),
                ),

              // Printed Folder Name Label across the bottom
              if (folder != null)
                Positioned(
                  bottom: 3,
                  left: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      folder!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderArtwork(BuildContext context, FolderModel folder) {
    final repTrack = folder.tracks.firstWhere(
      (t) => t.customArtPath != null && t.customArtPath!.isNotEmpty && File(t.customArtPath!).existsSync(),
      orElse: () => folder.tracks.firstWhere(
        (t) => t.albumId != null,
        orElse: () => folder.tracks.first,
      ),
    );

    if (repTrack.customArtPath != null &&
        repTrack.customArtPath!.isNotEmpty &&
        File(repTrack.customArtPath!).existsSync()) {
      return Image.file(
        File(repTrack.customArtPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } else if (repTrack.albumId != null) {
      return ArtworkWidget(
        id: repTrack.albumId,
        size: double.infinity,
        borderRadius: 0,
        title: folder.name,
        artist: '${folder.trackCount} tracks',
      );
    }
    return _buildFallback(context);
  }

  Widget _buildTrackArtwork(BuildContext context, AudioTrack track) {
    if (track.customArtPath != null &&
        track.customArtPath!.isNotEmpty &&
        File(track.customArtPath!).existsSync()) {
      return Image.file(
        File(track.customArtPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } else if (track.albumId != null) {
      return ArtworkWidget(
        id: track.albumId,
        size: double.infinity,
        borderRadius: 0,
        title: track.title,
        artist: track.artist,
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;
    return Container(
      color: const Color(0xFF22242B),
      child: Center(
        child: Icon(
          folder != null ? Icons.folder_rounded : Icons.music_note_rounded,
          color: accentColor.withAlpha(160),
          size: 24,
        ),
      ),
    );
  }
}

class _EmptyWindowPainter extends CustomPainter {
  final int index;
  const _EmptyWindowPainter(this.index);

  @override
  void paint(Canvas c, Size size) {
    const colors = [
      Color(0xFF7A3326),
      Color(0xFF34506F),
      Color(0xFFC98558),
      Color(0xFFDC7A2C),
      Color(0xFF3B66A8),
      Color(0xFFB9742C),
    ];
    final color = colors[index % colors.length];
    c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = color.withAlpha(200));
    c.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.28, Paint()..color = Colors.white24);
  }

  @override
  bool shouldRepaint(covariant _EmptyWindowPainter old) => old.index != index;
}

class _EuropeDiscPainter extends CustomPainter {
  final String title;
  final String subtitle;
  final String? description;
  final int trackCount;

  _EuropeDiscPainter({
    required this.title,
    required this.subtitle,
    this.description,
    required this.trackCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // View-Master Warm Cream Paper Disc Body
    final bodyPaint = Paint()
      ..color = const Color(0xFFF1EDE4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Subtle edge rim border
    final edgePaint = Paint()
      ..color = const Color(0xFFD6CEBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, edgePaint);

    // Radial drive pin detents / notches
    final notchPaint = Paint()
      ..color = const Color(0xFF141210)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final notchOffset = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      canvas.drawCircle(notchOffset, 3.5, notchPaint);
    }

    // Center Spindle Hub Ring
    final hubRingPaint = Paint()
      ..color = const Color(0xFFDDD5C5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.38, hubRingPaint);

    // Center Spindle Hole (Transparent cutout to reveal dark background)
    final holePaint = Paint()
      ..color = const Color(0xFF101014)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.11, holePaint);

    // Center Hub Notch Key
    final notchKeyPaint = Paint()
      ..color = const Color(0xFFDDD5C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.12, notchKeyPaint);

    // Printed Vintage Reel Typography on Disc Paper
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Reel Main Title
    textPainter.text = TextSpan(
      text: title,
      style: const TextStyle(
        fontFamily: 'serif',
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E1C1A),
        letterSpacing: 1.5,
      ),
    );
    textPainter.layout(maxWidth: radius * 0.65);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius * 0.28),
    );

    // Reel Subtitle
    textPainter.text = TextSpan(
      text: subtitle,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 8.5,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8C5D38),
        letterSpacing: 0.8,
      ),
    );
    textPainter.layout(maxWidth: radius * 0.65);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + radius * 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _EuropeDiscPainter old) =>
      old.title != title || old.subtitle != subtitle || old.trackCount != trackCount;
}

class _CanalScenePainter extends CustomPainter {
  const _CanalScenePainter();

  @override
  void paint(Canvas c, Size s) {
    final k = math.max(s.width / 736, s.height / 920);
    c.save();
    c.translate((s.width - 736 * k) / 2, (s.height - 920 * k) / 2);
    c.scale(k);

    Paint fill(Color col) => Paint()..color = col;

    // Sky
    c.drawRect(const Rect.fromLTWH(0, 0, 736, 920), fill(const Color(0xFF1A2222)));

    // Water
    c.drawRect(const Rect.fromLTWH(0, 360, 736, 560), fill(const Color(0xFF0D1412)));

    // Palace silhouettes & reflections
    c.drawRect(const Rect.fromLTWH(0, 100, 500, 260), fill(const Color(0xFF222C2A)));
    c.drawRect(const Rect.fromLTWH(520, 80, 216, 280), fill(const Color(0xFF1E2624)));

    // Water ripple reflections
    final ripplePaint = Paint()
      ..color = const Color(0x33446055)
      ..strokeWidth = 2.0;
    for (double y = 400; y < 900; y += 30) {
      c.drawLine(Offset(60, y), Offset(680, y), ripplePaint);
    }

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TokyoStudioScenePainter extends CustomPainter {
  const _TokyoStudioScenePainter();

  @override
  void paint(Canvas c, Size s) {
    final k = math.max(s.width / 736, s.height / 920);
    c.save();
    c.translate((s.width - 736 * k) / 2, (s.height - 920 * k) / 2);
    c.scale(k);

    Paint fill(Color col) => Paint()..color = col;

    // Tokyo Night Sky
    c.drawRect(const Rect.fromLTWH(0, 0, 736, 920), fill(const Color(0xFF140D1A)));

    // Studio Soundboard Silhouette
    c.drawRect(const Rect.fromLTWH(0, 500, 736, 420), fill(const Color(0xFF0A070E)));

    // Neon amber & violet console meter glows
    final amberGlow = Paint()..color = const Color(0x40FF9500);
    c.drawRect(const Rect.fromLTWH(120, 530, 200, 80), amberGlow);
    c.drawRect(const Rect.fromLTWH(420, 530, 200, 80), amberGlow);

    final neonLine = Paint()
      ..color = const Color(0x66FF5E36)
      ..strokeWidth = 2.0;
    c.drawLine(const Offset(40, 480), const Offset(700, 480), neonLine);

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalnutLoungeScenePainter extends CustomPainter {
  const _WalnutLoungeScenePainter();

  @override
  void paint(Canvas c, Size s) {
    final k = math.max(s.width / 736, s.height / 920);
    c.save();
    c.translate((s.width - 736 * k) / 2, (s.height - 920 * k) / 2);
    c.scale(k);

    Paint fill(Color col) => Paint()..color = col;

    // Rich Walnut acoustic room
    c.drawRect(const Rect.fromLTWH(0, 0, 736, 920), fill(const Color(0xFF19120C)));

    // Acoustic vertical wooden slats
    final slatPaint = fill(const Color(0xFF241A12));
    for (double x = 20; x < 720; x += 40) {
      c.drawRect(Rect.fromLTWH(x, 0, 18, 920), slatPaint);
    }

    // Vacuum tube amplifier warm amber glow
    final tubeGlow = Paint()
      ..color = const Color(0x35FFAE00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    c.drawCircle(const Offset(368, 650), 120, tubeGlow);

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
