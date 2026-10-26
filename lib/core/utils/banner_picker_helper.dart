import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/audio_player/domain/audio_track.dart';
import '../../features/audio_player/presentation/providers/audio_player_provider.dart';
import '../../features/library/presentation/providers/library_provider.dart';

class BannerPickerHelper {
  static Future<void> pickAndSetBanner({
    required BuildContext context,
    required WidgetRef ref,
    required AudioTrack track,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (files.isEmpty || files.first.path == null) {
        return;
      }

      final pickedPath = files.first.path!;

      if (!context.mounted) return;

      // Show option sheet: Track only vs Entire Album
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (dialogCtx) {
          final accentColor = Theme.of(dialogCtx).primaryColor;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    'APPLY BANNER ARTWORK',
                    style: AppTypography.monoSmall.copyWith(
                      color: accentColor,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how to apply this banner image across your local music library.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tapeAmber.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note, color: AppColors.tapeAmber),
                    ),
                    title: Text(
                      'Apply to this track only',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(track.title, maxLines: 1, style: AppTypography.bodySmall),
                    onTap: () async {
                      Navigator.of(dialogCtx).pop();
                      await ref.read(libraryNotifierProvider.notifier).updateSongCustomArt(track.id, pickedPath);
                      ref.read(playbackNotifierProvider.notifier).updateCurrentTrackArt(pickedPath);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceCard,
                            content: Text(
                              'Banner updated for "${track.title}"',
                              style: AppTypography.monoSmall.copyWith(color: accentColor),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.vhsCyan.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.album_outlined, color: AppColors.vhsCyan),
                    ),
                    title: Text(
                      'Apply to entire album',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(track.album, maxLines: 1, style: AppTypography.bodySmall),
                    onTap: () async {
                      Navigator.of(dialogCtx).pop();
                      await ref.read(libraryNotifierProvider.notifier).updateAlbumCustomArt(track.album, pickedPath);
                      ref.read(playbackNotifierProvider.notifier).updateCurrentTrackArt(pickedPath);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceCard,
                            content: Text(
                              'Banner updated for album "${track.album}"',
                              style: AppTypography.monoSmall.copyWith(color: AppColors.vhsCyan),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.vinylRed,
            content: Text('Failed to select banner: $e', style: AppTypography.monoSmall),
          ),
        );
      }
    }
  }
}
