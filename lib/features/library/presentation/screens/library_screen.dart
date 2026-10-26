import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/utils/banner_picker_helper.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/widgets/add_to_tape_modal.dart';
import 'package:spool/core/widgets/artwork_widget.dart';
import 'package:spool/core/widgets/europe_deluxe_disc.dart';
import 'package:spool/core/widgets/vhs_spine_card.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/library/presentation/providers/library_provider.dart';
import 'package:spool/features/library/presentation/screens/album_detail_screen.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedFolderIndex = 0;
  bool _isFolderDiscView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final accentColor = settings.accentColor;

    return Scaffold(
      backgroundColor: themePalette.background,
      appBar: AppBar(
        backgroundColor: themePalette.background,
        elevation: 0,
        title: Text(
          'MUSIC LIBRARY',
          style: AppTypography.displaySmall.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Add custom music folder',
            onPressed: () async {
              final selectedDir = await FilePicker.getDirectoryPath();
              if (selectedDir != null) {
                ref.read(libraryNotifierProvider.notifier).scanCustomFolder(selectedDir);
              }
            },
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            tooltip: 'Sort by',
            onSelected: (option) {
              ref.read(libraryNotifierProvider.notifier).setSort(option);
            },
            color: AppColors.surfaceElevated,
            itemBuilder: (context) => [
              _buildSortMenuItem(SortOption.title, 'Title', libraryState.sortOption, accentColor),
              _buildSortMenuItem(SortOption.artist, 'Artist', libraryState.sortOption, accentColor),
              _buildSortMenuItem(SortOption.album, 'Album', libraryState.sortOption, accentColor),
              _buildSortMenuItem(SortOption.duration, 'Duration', libraryState.sortOption, accentColor),
              _buildSortMenuItem(SortOption.dateAdded, 'Date Added', libraryState.sortOption, accentColor),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTypography.monoSmall.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'SONGS'),
            Tab(text: 'ALBUMS'),
            Tab(text: 'ARTISTS'),
            Tab(text: 'FOLDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSongsTab(libraryState),
          _buildAlbumsTab(libraryState),
          _buildArtistsTab(libraryState),
          _buildFoldersTab(libraryState),
        ],
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
    SortOption option,
    String label,
    SortOption current,
    Color accentColor,
  ) {
    final isSelected = option == current;
    return PopupMenuItem(
      value: option,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          if (isSelected) Icon(Icons.check, size: 18, color: accentColor),
        ],
      ),
    );
  }

  Widget _buildSongsTab(LibraryState state) {
    final songs = state.allSongs;
    if (songs.isEmpty) {
      return _buildEmptyState(
        'No Songs Found',
        'Tap the rescan icon or grant storage access to load your music library.',
      );
    }

    final playbackState = ref.watch(playbackNotifierProvider);
    final currentPlayingId = playbackState.currentTrack?.id;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final track = songs[index];
        final isPlayingThis = track.id == currentPlayingId;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ArtworkWidget(
            id: track.albumId,
            customArtPath: track.customArtPath,
            size: 48,
            title: track.title,
            artist: track.artist,
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isPlayingThis ? ref.read(settingsNotifierProvider).accentColor : AppColors.textPrimary,
              fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${track.artist} • ${track.album}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.formatDurationMs(track.durationMs),
                style: AppTypography.monoSmall.copyWith(
                  color: isPlayingThis ? AppColors.tapeAmber : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              IconButton(
                icon: Icon(
                  track.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: track.isFavorite ? AppColors.vinylRed : AppColors.textMuted,
                ),
                onPressed: () {
                  ref.read(playbackNotifierProvider.notifier).toggleFavorite(track);
                  ref.read(libraryNotifierProvider.notifier).loadFromDatabase();
                },
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                color: AppColors.surfaceElevated,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.playlist_add_rounded, color: AppColors.tapeAmber, size: 18),
                        SizedBox(width: 8),
                        Text('Record to Tape', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          AddToTapeModal.show(context, ref, track);
                        }
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: ref.read(settingsNotifierProvider).accentColor, size: 18),
                        const SizedBox(width: 8),
                        const Text('Set Banner Image', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          BannerPickerHelper.pickAndSetBanner(context: context, ref: ref, track: track);
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            ref.read(playbackNotifierProvider.notifier).playTrack(
              track,
              queue: songs,
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsTab(LibraryState state) {
    final albums = state.albums;
    if (albums.isEmpty) {
      return _buildEmptyState('No Albums Found', 'Your music files have no album tags or storage is unindexed.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700
            ? 4
            : (constraints.maxWidth > 480 ? 3 : 2);

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
        final album = albums[index];
        final spineColor = AppColors.spinePalette[index % AppColors.spinePalette.length];

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AlbumDetailScreen(album: album)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
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
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: spineColor,
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
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildArtistsTab(LibraryState state) {
    final artists = state.artists;
    if (artists.isEmpty) {
      return _buildEmptyState('No Artists Found', 'Scan your local storage to index artists.');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final tabColor = AppColors.spinePalette[index % AppColors.spinePalette.length];

        return VhsSpineCard(
          title: artist.name,
          subtitle: '${artist.albumCount} albums • ${artist.trackCount} tracks',
          tabColor: tabColor,
          onTap: () {
            ref.read(playbackNotifierProvider.notifier).playTrack(
              artist.tracks.first,
              queue: artist.tracks,
            );
          },
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        );
      },
    );
  }

  Widget _buildFoldersTab(LibraryState state) {
    final folders = state.folders;
    if (folders.isEmpty) {
      return _buildEmptyState('No Folders Found', 'Use the folder icon at the top right to select a custom music folder.');
    }

    final safeFolderIndex = _selectedFolderIndex.clamp(0, folders.length - 1);
    final settings = ref.watch(settingsNotifierProvider);

    return Column(
      children: [
        // Top Folder Selector Bar & Mode Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF111116),
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
          ),
          child: Row(
            children: [
              // Scrollable Folder Chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (int i = 0; i < folders.length; i++) ...[
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedFolderIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: i == safeFolderIndex
                                  ? ref.read(settingsNotifierProvider).accentColor
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: i == safeFolderIndex
                                    ? ref.read(settingsNotifierProvider).accentColor
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 14,
                                  color: i == safeFolderIndex ? Colors.white : AppColors.tapeAmber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  folders[i].name,
                                  style: AppTypography.monoSmall.copyWith(
                                    color: i == safeFolderIndex ? Colors.white : AppColors.textPrimary,
                                    fontWeight: i == safeFolderIndex ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${folders[i].trackCount}',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: i == safeFolderIndex ? Colors.white70 : AppColors.textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Add Folder Chip
                      InkWell(
                        onTap: () async {
                          final selectedDir = await FilePicker.getDirectoryPath();
                          if (selectedDir != null) {
                            ref.read(libraryNotifierProvider.notifier).scanCustomFolder(selectedDir);
                          }
                        },
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
                                'ADD FOLDER',
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

              const SizedBox(width: 8),

              // View Mode Toggle (Disc vs List)
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
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      tooltip: 'View-Master Reel Disc',
                      icon: Icon(
                        Icons.album_outlined,
                        color: _isFolderDiscView ? ref.read(settingsNotifierProvider).accentColor : AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _isFolderDiscView = true),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      tooltip: 'VHS Spine List',
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: !_isFolderDiscView ? ref.read(settingsNotifierProvider).accentColor : AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _isFolderDiscView = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Folder Content: View-Master Disc or List View
        Expanded(
          child: _isFolderDiscView
              ? EuropeDeluxeDisc(
                  title: 'FOLDERS REEL',
                  subtitle: '${folders.length} DIRECTORIES INDEXED',
                  folders: folders,
                  settings: settings,
                  onFolderTap: (folder) {
                    if (folder.tracks.isNotEmpty) {
                      ref.read(playbackNotifierProvider.notifier).playTrack(
                        folder.tracks.first,
                        queue: folder.tracks,
                      );
                    }
                  },
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final tabColor = AppColors.spinePalette[index % AppColors.spinePalette.length];

                    return VhsSpineCard(
                      title: folder.name,
                      subtitle: '${folder.trackCount} songs • ${folder.path}',
                      tabColor: tabColor,
                      onTap: () {
                        setState(() {
                          _selectedFolderIndex = index;
                          _isFolderDiscView = true;
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: AppColors.textOnCream, size: 28),
                        onPressed: () {
                          if (folder.tracks.isNotEmpty) {
                            ref.read(playbackNotifierProvider.notifier).playTrack(
                              folder.tracks.first,
                              queue: folder.tracks,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music_outlined, size: 60, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parchment,
                foregroundColor: AppColors.textOnCream,
              ),
              icon: const Icon(Icons.sync),
              label: Text('SCAN DEVICE STORAGE', style: AppTypography.monoSmall.copyWith(color: AppColors.textOnCream, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(libraryNotifierProvider.notifier).rescan();
              },
            ),
          ],
        ),
      ),
    );
  }
}
