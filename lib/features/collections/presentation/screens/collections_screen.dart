import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/add_to_tape_modal.dart';
import 'package:spool/core/widgets/artwork_widget.dart';
import 'package:spool/core/widgets/europe_deluxe_disc.dart';
import 'package:spool/core/widgets/vhs_spine_card.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/collections/domain/playlist_model.dart';
import 'package:spool/features/collections/presentation/providers/collections_provider.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  int _selectedPlaylistIndex = 0;
  bool _isPlaylistDiscView = true;
  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);

    return Scaffold(
      backgroundColor: themePalette.background,
      appBar: AppBar(
        backgroundColor: themePalette.background,
        elevation: 0,
        title: Text(
          'COLLECTIONS',
          style: AppTypography.displaySmall.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonOrange),
            tooltip: 'New Mixtape Playlist',
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Favorites Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FAVORITE TRACKS',
                  style: AppTypography.monoSmall.copyWith(letterSpacing: 2, color: AppColors.vinylRed),
                ),
                Text(
                  '${collections.favorites.length} TRACKS',
                  style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (collections.favorites.isEmpty)
            _buildEmptySection('No Favorites Yet', 'Tap the heart icon on any track to pin it here.')
          else
            ...collections.favorites.take(5).map((track) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: ArtworkWidget(
                  id: track.albumId,
                  customArtPath: track.customArtPath,
                  size: 40,
                  title: track.title,
                  artist: track.artist,
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${track.artist} â€¢ ${track.album}', style: AppTypography.bodySmall),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.formatDurationMs(track.durationMs),
                      style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_add_rounded, color: AppColors.tapeAmber, size: 20),
                      tooltip: 'Record to Tape',
                      onPressed: () => AddToTapeModal.show(context, ref, track),
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(playbackNotifierProvider.notifier).playTrack(
                    track,
                    queue: collections.favorites,
                  );
                },
              );
            }),

          const SizedBox(height: 16),

          // Mixtapes / Custom Playlists Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'MIXTAPES & PLAYLISTS',
                      style: AppTypography.monoSmall.copyWith(letterSpacing: 2, color: AppColors.tapeAmber),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${collections.playlists.length}',
                        style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                if (collections.playlists.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.all(5),
                              constraints: const BoxConstraints(),
                              tooltip: 'View-Master Reel Disc',
                              icon: Icon(
                                Icons.album_outlined,
                                color: _isPlaylistDiscView ? AppColors.neonOrange : AppColors.textMuted,
                              ),
                              onPressed: () => setState(() => _isPlaylistDiscView = true),
                            ),
                            IconButton(
                              iconSize: 18,
                              padding: const EdgeInsets.all(5),
                              constraints: const BoxConstraints(),
                              tooltip: 'VHS Spine List',
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: !_isPlaylistDiscView ? AppColors.neonOrange : AppColors.textMuted,
                              ),
                              onPressed: () => setState(() => _isPlaylistDiscView = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (collections.playlists.isEmpty)
            _buildEmptySection(
              'No Custom Mixtapes',
              'Create a custom mixtape to group your favorite songs together.',
              action: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.parchment,
                  foregroundColor: AppColors.textOnCream,
                ),
                icon: const Icon(Icons.add),
                label: Text('CREATE MIXTAPE', style: AppTypography.monoSmall.copyWith(color: AppColors.textOnCream, fontWeight: FontWeight.bold)),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            )
          else if (_isPlaylistDiscView) ...[
            // Tape Selector Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (int i = 0; i < collections.playlists.length; i++) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedPlaylistIndex = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: i == _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1)
                                ? Color(collections.playlists[i].colorAccent)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: i == _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1)
                                  ? Colors.white54
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(collections.playlists[i].colorAccent),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                collections.playlists[i].name,
                                style: AppTypography.monoSmall.copyWith(
                                  color: i == _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1)
                                      ? (Color(collections.playlists[i].colorAccent).computeLuminance() > 0.4 ? Colors.black : Colors.white)
                                      : AppColors.textPrimary,
                                  fontWeight: i == _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${collections.playlists[i].trackCount}',
                                style: AppTypography.monoSmall.copyWith(
                                  color: i == _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1)
                                      ? (Color(collections.playlists[i].colorAccent).computeLuminance() > 0.4 ? Colors.black54 : Colors.white70)
                                      : AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Add New Tape Chip
                    InkWell(
                      onTap: () => _showCreatePlaylistDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.tapeAmber.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 14, color: AppColors.tapeAmber),
                            const SizedBox(width: 4),
                            Text(
                              'NEW TAPE',
                              style: AppTypography.monoSmall.copyWith(color: AppColors.tapeAmber, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Active Playlist Reel Disc
            Builder(
              builder: (context) {
                final safeIndex = _selectedPlaylistIndex.clamp(0, collections.playlists.length - 1);
                final selectedPlaylist = collections.playlists[safeIndex];

                return FutureBuilder<List<AudioTrack>>(
                  future: ref.read(collectionsNotifierProvider.notifier).getPlaylistSongs(selectedPlaylist.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 380,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.tapeAmber),
                        ),
                      );
                    }
                    final songs = snapshot.data ?? [];
                    if (songs.isEmpty) {
                      return _buildEmptySection(
                        'Tape "${selectedPlaylist.name}" is Blank',
                        'Add songs to this tape by tapping the record tape icon in Library or Now Playing.',
                        action: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.tapeAmber),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('INSPECT TAPE'),
                              onPressed: () => _showPlaylistDetail(context, selectedPlaylist),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: AppColors.vinylRed),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('DELETE'),
                              onPressed: () {
                                ref.read(collectionsNotifierProvider.notifier).deletePlaylist(selectedPlaylist.id);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: 480,
                      child: EuropeDeluxeDisc(
                        title: selectedPlaylist.name.toUpperCase(),
                        subtitle: '${songs.length} TRACKS â€¢ ANALOG REEL',
                        description: 'Spool Custom Mixtape',
                        tracks: songs,
                        activeTrackId: ref.watch(playbackNotifierProvider).currentTrack?.id,
                        settings: ref.watch(settingsNotifierProvider),
                        onTrackTap: (track) {
                          ref.read(playbackNotifierProvider.notifier).playTrack(
                            track,
                            queue: songs,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ] else
            ...collections.playlists.map((playlist) {
              return VhsSpineCard(
                title: playlist.name,
                subtitle: '${playlist.trackCount} tracks',
                tabColor: Color(playlist.colorAccent),
                onTap: () => _showPlaylistDetail(context, playlist),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textOnCream, size: 20),
                  color: AppColors.surfaceElevated,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Delete Mixtape', style: TextStyle(color: AppColors.vinylRed)),
                      onTap: () {
                        ref.read(collectionsNotifierProvider.notifier).deletePlaylist(playlist.id);
                      },
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          // Most Played Section
          if (collections.mostPlayed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MOST ROTATED',
                    style: AppTypography.monoSmall.copyWith(letterSpacing: 2, color: AppColors.vhsCyan),
                  ),
                  Text(
                    'TOP SPINS',
                    style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            ...collections.mostPlayed.take(5).map((track) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${track.playCount}x',
                    style: AppTypography.monoSmall.copyWith(color: AppColors.vhsCyan, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${track.artist} â€¢ ${track.album}', style: AppTypography.bodySmall),
                onTap: () {
                  ref.read(playbackNotifierProvider.notifier).playTrack(
                    track,
                    queue: collections.mostPlayed,
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title, String subtitle, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Column(
        children: [
          Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    Color selectedColor = AppColors.spinePalette.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.darkCharcoal,
            title: Text('NEW MIXTAPE', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Midnight Tape 1984',
                    hintStyle: AppTypography.bodySmall,
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonOrange)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('CASSETTE LABEL ACCENT', style: AppTypography.monoSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: AppColors.spinePalette.take(6).map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('CANCEL', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(collectionsNotifierProvider.notifier).createPlaylist(
                      name,
                      selectedColor.toARGB32(),
                    );
                    Navigator.of(dialogCtx).pop();
                  }
                },
                child: Text('CREATE', style: AppTypography.monoSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlaylistDetail(BuildContext context, PlaylistModel playlist) async {
    final songs = await ref.read(collectionsNotifierProvider.notifier).getPlaylistSongs(playlist.id);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCharcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        bool showDiscView = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(playlist.colorAccent),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(playlist.name, style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                                Text('${songs.length} tracks in this mixtape', style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                          if (songs.isNotEmpty) ...[
                            IconButton(
                              icon: Icon(
                                showDiscView ? Icons.view_list_rounded : Icons.album_outlined,
                                color: AppColors.tapeAmber,
                              ),
                              tooltip: showDiscView ? 'Track List' : 'View-Master Disc',
                              onPressed: () => setSheetState(() => showDiscView = !showDiscView),
                            ),
                            const SizedBox(width: 4),
                            IconButton.filled(
                              style: IconButton.styleFrom(backgroundColor: AppColors.neonOrange),
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              onPressed: () {
                                ref.read(playbackNotifierProvider.notifier).playTrack(songs.first, queue: songs);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: songs.isEmpty
                        ? Center(
                            child: Text(
                              'No tracks yet in this mixtape.\nAdd songs from the library.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium,
                            ),
                          )
                        : (showDiscView
                            ? EuropeDeluxeDisc(
                                title: playlist.name.toUpperCase(),
                                subtitle: '${songs.length} TRACKS â€¢ MIXTAPE',
                                description: 'Spool Custom Mixtape',
                                tracks: songs,
                                activeTrackId: ref.watch(playbackNotifierProvider).currentTrack?.id,
                                settings: ref.watch(settingsNotifierProvider),
                                onTrackTap: (track) {
                                  ref.read(playbackNotifierProvider.notifier).playTrack(track, queue: songs);
                                },
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: songs.length,
                                itemBuilder: (context, index) {
                                  final song = songs[index];
                                  return ListTile(
                                    leading: Text('${index + 1}', style: AppTypography.monoSmall),
                                    title: Text(song.title, maxLines: 1),
                                    subtitle: Text(song.artist, maxLines: 1),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.vinylRed, size: 20),
                                      onPressed: () {
                                        ref.read(collectionsNotifierProvider.notifier).removeSongFromPlaylist(playlist.id, song.id);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    onTap: () {
                                      ref.read(playbackNotifierProvider.notifier).playTrack(song, queue: songs);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              )),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
