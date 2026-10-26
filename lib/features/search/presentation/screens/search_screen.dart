import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/add_to_tape_modal.dart';
import '../../../../core/widgets/artwork_widget.dart';
import '../../../audio_player/presentation/providers/audio_player_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final accentColor = settings.accentColor;

    return Scaffold(
      backgroundColor: themePalette.background,
      appBar: AppBar(
        backgroundColor: themePalette.background,
        elevation: 0,
        title: Text(
          'SEARCH ARCHIVE',
          style: AppTypography.displaySmall.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search Input Field with Analog aesthetic
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: accentColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchNotifierProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 1.2),
                ),
              ),
              onChanged: (query) {
                ref.read(searchNotifierProvider.notifier).search(query);
                setState(() {});
              },
            ),
          ),

          // Search Results
          Expanded(
            child: searchState.isSearching
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : searchState.query.isEmpty
                    ? _buildSearchPrompt()
                    : searchState.results.isEmpty
                        ? _buildNoResults(searchState.query)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: searchState.results.length,
                            itemBuilder: (context, index) {
                              final track = searchState.results[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: ArtworkWidget(
                                  id: track.albumId,
                                  customArtPath: track.customArtPath,
                                  size: 46,
                                  title: track.title,
                                  artist: track.artist,
                                ),
                                title: Text(
                                  track.title,
                                  maxLines: 1,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${track.artist} â€¢ ${track.album}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Formatters.formatDurationMs(track.durationMs),
                                      style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted),
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
                                    queue: searchState.results,
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_search_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Search Local Archive', style: AppTypography.displaySmall.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('Type a track name, artist, or album', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No Matches for "$query"', style: AppTypography.displaySmall.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('Try checking spelling or rescan your library', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
