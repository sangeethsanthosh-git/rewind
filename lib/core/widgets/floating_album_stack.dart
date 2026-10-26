import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'artwork_widget.dart';
import '../../features/library/domain/album_model.dart';
import '../../features/audio_player/domain/audio_track.dart';

class FloatingAlbumStack extends StatefulWidget {
  final List<AlbumModel> albums;
  final Function(AlbumModel album) onAlbumTap;
  final Function(AudioTrack track)? onTrackTap;

  const FloatingAlbumStack({
    super.key,
    required this.albums,
    required this.onAlbumTap,
    this.onTrackTap,
  });

  @override
  State<FloatingAlbumStack> createState() => _FloatingAlbumStackState();
}

class _FloatingAlbumStackState extends State<FloatingAlbumStack> {
  late final ScrollController _scrollController;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || widget.albums.isEmpty) return;
    const itemHeight = 110.0;
    final index = (_scrollController.offset / itemHeight).round().clamp(0, widget.albums.length - 1);
    if (index != _focusedIndex) {
      setState(() {
        _focusedIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.albums.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 380,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: widget.albums.length,
        itemBuilder: (context, index) {
          final album = widget.albums[index];
          final spineColor = AppColors.spinePalette[index % AppColors.spinePalette.length];
          final isFocused = index == _focusedIndex;

          return _FloatingAlbumSlab(
            album: album,
            spineColor: spineColor,
            isFocused: isFocused,
            onTap: () => widget.onAlbumTap(album),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle.withAlpha(120)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.album_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Your Vinyl Collection is Empty',
            style: AppTypography.displaySmall.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan device storage to load your music',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FloatingAlbumSlab extends StatelessWidget {
  final AlbumModel album;
  final Color spineColor;
  final bool isFocused;
  final VoidCallback onTap;

  const _FloatingAlbumSlab({
    required this.album,
    required this.spineColor,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstTrack = album.tracks.isNotEmpty ? album.tracks.first : null;
    final trackTitle = firstTrack?.title ?? album.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0018)
            ..rotateX(-0.48)
            ..multiply(Matrix4.diagonal3Values(isFocused ? 1.04 : 0.98, isFocused ? 1.04 : 0.98, 1.0)),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.obsidian,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isFocused ? 180 : 120),
                      blurRadius: isFocused ? 20 : 12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ArtworkWidget(
                        id: album.albumId,
                        customArtPath: album.customArtPath,
                        size: double.infinity,
                        borderRadius: 0,
                        title: album.title,
                        artist: album.artist,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withAlpha(25),
                              Colors.transparent,
                              Colors.black.withAlpha(60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 38,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: spineColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(160),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$trackTitle  ',
                              style: AppTypography.cassetteHeader.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: album.artist,
                              style: AppTypography.cassetteSub.copyWith(
                                color: Colors.white.withAlpha(220),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(60),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${album.trackCount} TRK',
                        style: AppTypography.monoSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
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
}
