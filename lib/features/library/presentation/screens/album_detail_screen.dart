import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/banner_picker_helper.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/add_to_tape_modal.dart';
import '../../../../core/widgets/artwork_widget.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../audio_player/domain/audio_track.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/album_model.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final currentPlayingId = playbackState.currentTrack?.id;

    return Scaffold(
      backgroundColor: themePalette.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible Retro App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.darkCharcoal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
                tooltip: 'Set Album Banner Image',
                onPressed: () {
                  if (album.tracks.isNotEmpty) {
                    BannerPickerHelper.pickAndSetBanner(context: context, ref: ref, track: album.tracks.first);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkWidget(
                    id: album.albumId,
                    customArtPath: album.customArtPath,
                    size: double.infinity,
                    borderRadius: 0,
                    title: album.title,
                    artist: album.artist,
                    onAddBanner: () {
                      if (album.tracks.isNotEmpty) {
                        BannerPickerHelper.pickAndSetBanner(context: context, ref: ref, track: album.tracks.first);
                      }
                    },
                  ),
                  // Dark analog gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(40),
                          Colors.black.withAlpha(160),
                          AppColors.obsidian,
                        ],
                      ),
                    ),
                  ),
                  // Album info at the bottom of the header
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tapeAmber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ALBUM RELEASE',
                            style: AppTypography.monoSmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displayMedium.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artist,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play & Shuffle Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.parchment,
                        foregroundColor: AppColors.textOnCream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        'PLAY ALL (${album.trackCount})',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textOnCream,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        if (album.tracks.isNotEmpty) {
                          ref.read(playbackNotifierProvider.notifier).playTrack(
                            album.tracks.first,
                            queue: album.tracks,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.shuffle, color: AppColors.neonOrange),
                    tooltip: 'Shuffle Album',
                    onPressed: () {
                      if (album.tracks.isNotEmpty) {
                        final shuffled = List<AudioTrack>.from(album.tracks)..shuffle();
                        ref.read(playbackNotifierProvider.notifier).playTrack(
                          shuffled.first,
                          queue: shuffled,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Track List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = album.tracks[index];
                final isCurrent = track.id == currentPlayingId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: SizedBox(
                    width: 28,
                    child: Text(
                      '${track.trackNumber ?? (index + 1)}',
                      style: AppTypography.monoSmall.copyWith(
                        color: isCurrent ? AppColors.neonOrange : AppColors.textMuted,
                      ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isCurrent ? AppColors.neonOrange : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${track.fileExtension.toUpperCase()} • ${Formatters.formatDurationMs(track.durationMs)}',
                    style: AppTypography.monoSmall.copyWith(
                      color: isCurrent ? AppColors.tapeAmber : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent && playbackState.isPlaying)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.graphic_eq, color: AppColors.neonOrange, size: 20),
                        ),
                      IconButton(
                        icon: const Icon(Icons.playlist_add_rounded, size: 20, color: AppColors.tapeAmber),
                        tooltip: 'Record to Tape',
                        onPressed: () => AddToTapeModal.show(context, ref, track),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(playbackNotifierProvider.notifier).playTrack(
                      track,
                      queue: album.tracks,
                    );
                  },
                );
              },
              childCount: album.tracks.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
