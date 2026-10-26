import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/library/domain/album_model.dart';
import 'artwork_widget.dart';

class ViewMasterReelWidget extends StatefulWidget {
  final List<AlbumModel> albums;
  final Function(AlbumModel album) onAlbumSelected;

  const ViewMasterReelWidget({
    super.key,
    required this.albums,
    required this.onAlbumSelected,
  });

  @override
  State<ViewMasterReelWidget> createState() => _ViewMasterReelWidgetState();
}

class _ViewMasterReelWidgetState extends State<ViewMasterReelWidget> {
  double _currentAngle = 0.0;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.albums.isEmpty) return const SizedBox.shrink();

    final visibleAlbums = widget.albums.take(7).toList();
    final itemCount = visibleAlbums.length;
    final anglePerItem = (2 * math.pi) / (itemCount > 0 ? itemCount : 1);

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _currentAngle += details.primaryDelta! * 0.01;
              final normalized = (-_currentAngle / anglePerItem).round() % itemCount;
              _selectedIndex = normalized >= 0 ? normalized : normalized + itemCount;
            });
          },
          onTap: () {
            if (_selectedIndex >= 0 && _selectedIndex < visibleAlbums.length) {
              widget.onAlbumSelected(visibleAlbums[_selectedIndex]);
            }
          },
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE2DDD3), // Vintage cream paper disc
              border: Border.all(color: const Color(0xFFBEB5A4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center spindle hole
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF222226),
                    border: Border.all(color: const Color(0xFFC0A060), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ),
                ),

                // Radial photo windows
                for (int i = 0; i < itemCount; i++) ...[
                  Transform.rotate(
                    angle: _currentAngle + (i * anglePerItem),
                    child: Align(
                      alignment: const Alignment(0, -0.78),
                      child: Container(
                        width: 50,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _selectedIndex == i ? Theme.of(context).primaryColor : const Color(0xFF44444C),
                            width: _selectedIndex == i ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            if (_selectedIndex == i)
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withAlpha(140),
                                blurRadius: 8,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: ArtworkWidget(
                            id: visibleAlbums[i].albumId,
                            customArtPath: visibleAlbums[i].customArtPath,
                            size: 40,
                            borderRadius: 2,
                            title: visibleAlbums[i].title,
                            artist: visibleAlbums[i].artist,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Subtle radial text "VIEW-MASTER SPOOL STEREO REEL"
                Positioned(
                  bottom: 30,
                  child: Text(
                    'VIEW-MASTER • STEREO REEL',
                    style: AppTypography.monoSmall.copyWith(
                      color: const Color(0xFF6B6458),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visibleAlbums.isNotEmpty && _selectedIndex < visibleAlbums.length) ...[
          Text(
            visibleAlbums[_selectedIndex].title,
            maxLines: 1,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            visibleAlbums[_selectedIndex].artist,
            maxLines: 1,
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.tapeAmber,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
