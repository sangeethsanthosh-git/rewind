import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ArtworkWidget extends StatelessWidget {
  final int? id;
  final int? albumId;
  final String? customArtPath;
  final ArtworkType type;
  final double size;
  final double borderRadius;
  final String title;
  final String? artist;
  final VoidCallback? onAddBanner;

  const ArtworkWidget({
    super.key,
    required this.id,
    this.albumId,
    this.customArtPath,
    this.type = ArtworkType.AUDIO,
    this.size = 56,
    this.borderRadius = 8,
    required this.title,
    this.artist,
    this.onAddBanner,
  });

  @override
  Widget build(BuildContext context) {
    if (customArtPath != null && customArtPath!.isNotEmpty) {
      final file = File(customArtPath!);
      if (file.existsSync()) {
        final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
        final targetPx = (size * dpr).round();
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: size,
            height: size,
            cacheWidth: targetPx > 0 ? targetPx : null,
            cacheHeight: targetPx > 0 ? targetPx : null,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackQuery(context),
          ),
        );
      }
    }

    return _buildFallbackQuery(context);
  }

  Widget _buildFallbackQuery(BuildContext context) {
    if (id != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: QueryArtworkWidget(
          id: id!,
          type: type,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.circular(borderRadius),
          nullArtworkWidget: _buildAlbumFallback(context),
          errorBuilder: (context, error, stackTrace) => _buildAlbumFallback(context),
        ),
      );
    }

    return _buildAlbumFallback(context);
  }

  Widget _buildAlbumFallback(BuildContext context) {
    if (albumId != null && (type != ArtworkType.ALBUM || id != albumId)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: QueryArtworkWidget(
          id: albumId!,
          type: ArtworkType.ALBUM,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.circular(borderRadius),
          nullArtworkWidget: _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
        ),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final hash = title.hashCode.abs();
    final accentColor = AppColors.spinePalette[hash % AppColors.spinePalette.length];

    final isLargeBanner = size >= 140;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: accentColor.withAlpha(90),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GroovePainter(accentColor.withAlpha(45)),
          ),
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.1,
                height: size * 0.1,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ),
          if (isLargeBanner && onAddBanner != null)
            Positioned(
              bottom: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddBanner,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).primaryColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(140),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ADD BANNER',
                          style: AppTypography.monoSmall.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (size >= 80)
            Positioned(
              bottom: 8,
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'â™«',
                style: AppTypography.monoSmall.copyWith(
                  color: Colors.white.withAlpha(200),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroovePainter extends CustomPainter {
  final Color color;

  _GroovePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (double r = maxRadius * 0.45; r < maxRadius * 0.9; r += 5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
