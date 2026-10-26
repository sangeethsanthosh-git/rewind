import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/mechanical_sound_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/artwork_widget.dart';
import '../../../../core/widgets/europe_deluxe_disc.dart';
import '../../../../core/widgets/vhs_spine_card.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/folder_model.dart';
import '../providers/library_provider.dart';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  bool _isDiscView = true;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final accentColor = settings.accentColor;
    final folders = libraryState.folders;

    return Scaffold(
      backgroundColor: themePalette.background,
      appBar: AppBar(
        backgroundColor: themePalette.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALOG FOLDERS',
              style: AppTypography.displaySmall.copyWith(fontSize: 18),
            ),
            Text(
              '${folders.length} DIRECTORIES INDEXED',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.tapeAmber,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Scan or Add Folder
          IconButton(
            icon: Icon(Icons.create_new_folder_outlined, color: accentColor),
            tooltip: 'Add Music Folder',
            onPressed: () async {
              final selectedDir = await FilePicker.getDirectoryPath();
              if (selectedDir != null) {
                ref.read(libraryNotifierProvider.notifier).scanCustomFolder(selectedDir);
              }
            },
          ),
          // View Mode Switcher: Disc vs Spine
          IconButton(
            icon: Icon(
              _isDiscView ? Icons.view_list_rounded : Icons.album_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: _isDiscView ? 'Switch to VHS Spine List' : 'Switch to View-Master Disc',
            onPressed: () {
              MechanicalSoundService.instance.playMechanicalSound(
                MechanicalSoundType.skipClick,
                settings: settings,
              );
              setState(() => _isDiscView = !_isDiscView);
            },
          ),
        ],
      ),
      body: folders.isEmpty
          ? _buildEmptyState(context)
          : (_isDiscView
              ? EuropeDeluxeDisc(
                  title: 'FOLDERS REEL',
                  subtitle: '${folders.length} FOLDERS INDEXED',
                  folders: folders,
                  settings: settings,
                  onFolderTap: (folder) => _showFolderTracks(context, ref, folder),
                )
              : _buildFolderListView(context, ref, folders)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tapeAmber.withAlpha(100), width: 1.5),
              ),
              child: const Icon(Icons.folder_open_rounded, size: 52, color: AppColors.tapeAmber),
            ),
            const SizedBox(height: 20),
            Text(
              'No Music Folders Loaded',
              style: AppTypography.displaySmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan device storage or choose a folder containing FLAC, MP3, AAC, or WAV files.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: Text(
                'SCAN MUSIC DIRECTORY',
                style: AppTypography.monoSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () async {
                final selectedDir = await FilePicker.getDirectoryPath();
                if (selectedDir != null) {
                  ref.read(libraryNotifierProvider.notifier).scanCustomFolder(selectedDir);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderListView(BuildContext context, WidgetRef ref, List<FolderModel> folders) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12).copyWith(bottom: 100),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final tabColor = AppColors.spinePalette[index % AppColors.spinePalette.length];

        return VhsSpineCard(
          title: folder.name,
          subtitle: '${folder.trackCount} tracks • ${folder.path}',
          tabColor: tabColor,
          dateBadge: '${folder.trackCount} TRKS',
          onTap: () => _showFolderTracks(context, ref, folder),
        );
      },
    );
  }

  void _showFolderTracks(BuildContext context, WidgetRef ref, FolderModel folder) {
    final settings = ref.read(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final accentColor = settings.accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themePalette.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tapeAmber.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.tapeAmber.withAlpha(120), width: 1),
                        ),
                        child: const Icon(Icons.folder_rounded, color: AppColors.tapeAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displaySmall.copyWith(fontSize: 16),
                            ),
                            Text(
                              '${folder.trackCount} TRACKS • ${folder.path}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.monoSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Play All Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text(
                          'PLAY ALL',
                          style: AppTypography.monoSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        onPressed: () {
                          if (folder.tracks.isNotEmpty) {
                            MechanicalSoundService.instance.playMechanicalSound(
                              MechanicalSoundType.playClack,
                              settings: settings,
                            );
                            ref.read(playbackNotifierProvider.notifier).playTrack(
                              folder.tracks.first,
                              queue: folder.tracks,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderSubtle, height: 1),
                // Tracklist
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 40),
                    itemCount: folder.tracks.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Color(0x1AFFFFFF),
                      height: 1,
                      indent: 68,
                    ),
                    itemBuilder: (context, idx) {
                      final track = folder.tracks[idx];
                      return ListTile(
                        leading: ArtworkWidget(
                          id: int.tryParse(track.id),
                          albumId: track.albumId,
                          customArtPath: track.customArtPath,
                          size: 42,
                          borderRadius: 6,
                          title: track.title,
                          artist: track.artist,
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.fileExtension.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                        trailing: Text(
                          Formatters.formatDuration(Duration(milliseconds: track.durationMs)),
                          style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                        ),
                        onTap: () {
                          MechanicalSoundService.instance.playMechanicalSound(
                            MechanicalSoundType.playClack,
                            settings: settings,
                          );
                          ref.read(playbackNotifierProvider.notifier).playTrack(
                            track,
                            queue: folder.tracks,
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
