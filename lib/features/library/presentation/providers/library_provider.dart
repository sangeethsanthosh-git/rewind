import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:spool/core/database/app_database.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/library/data/music_scanner_service.dart';
import 'package:spool/features/library/domain/album_model.dart';
import 'package:spool/features/library/domain/artist_model.dart';
import 'package:spool/features/library/domain/folder_model.dart';

enum SortOption {
  title,
  artist,
  album,
  duration,
  dateAdded,
  trackNumber,
}

class LibraryState {
  final List<AudioTrack> allSongs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<FolderModel> folders;
  final bool isLoading;
  final ScanProgress? scanProgress;
  final SortOption sortOption;
  final bool sortAscending;
  final String? errorMessage;

  const LibraryState({
    this.allSongs = const [],
    this.albums = const [],
    this.artists = const [],
    this.folders = const [],
    this.isLoading = false,
    this.scanProgress,
    this.sortOption = SortOption.title,
    this.sortAscending = true,
    this.errorMessage,
  });

  LibraryState copyWith({
    List<AudioTrack>? allSongs,
    List<AlbumModel>? albums,
    List<ArtistModel>? artists,
    List<FolderModel>? folders,
    bool? isLoading,
    ScanProgress? scanProgress,
    SortOption? sortOption,
    bool? sortAscending,
    String? errorMessage,
  }) {
    return LibraryState(
      allSongs: allSongs ?? this.allSongs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      scanProgress: scanProgress ?? this.scanProgress,
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final MusicScannerService _scanner = MusicScannerService();

  LibraryNotifier() : super(const LibraryState()) {
    _initScannerListener();
    loadFromDatabase();
  }

  void _initScannerListener() {
    _scanner.progressStream.listen((progress) {
      state = state.copyWith(
        scanProgress: progress,
        isLoading: progress.isScanning,
      );
      if (!progress.isScanning && progress.scannedCount > 0) {
        loadFromDatabase();
      }
    });
  }

  Future<void> loadFromDatabase() async {
    state = state.copyWith(isLoading: true);
    try {
      var songs = await AppDatabase.instance.getAllSongs();
      if (songs.isEmpty) {
        // Auto-scan known folders if library is empty
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null) {
            final downloads = Directory('$userProfile\\Downloads');
            if (downloads.existsSync()) {
              await _scanner.scanCustomFolder(downloads.path);
              songs = await AppDatabase.instance.getAllSongs();
            }
          }
        }
      }
      final sortedSongs = _applySort(songs, state.sortOption, state.sortAscending);

      final albums = _groupAlbums(sortedSongs);
      final artists = _groupArtists(sortedSongs);
      final folders = _groupFolders(sortedSongs);

      state = state.copyWith(
        allSongs: sortedSongs,
        albums: albums,
        artists: artists,
        folders: folders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library: $e',
      );
    }
  }

  Future<void> rescan({List<String> excludedFolders = const []}) async {
    await _scanner.scanMediaStore(excludedFolders: excludedFolders);
    await loadFromDatabase();
  }

  Future<void> scanCustomFolder(String path) async {
    await _scanner.scanCustomFolder(path);
    await loadFromDatabase();
  }

  Future<void> updateSongCustomArt(String songId, String artPath) async {
    await AppDatabase.instance.updateSongCustomArt(songId, artPath);
    await loadFromDatabase();
  }

  Future<void> updateAlbumCustomArt(String album, String artPath) async {
    await AppDatabase.instance.updateAlbumCustomArt(album, artPath);
    await loadFromDatabase();
  }

  void setSort(SortOption option, [bool? ascending]) {
    final asc = ascending ?? (state.sortOption == option ? !state.sortAscending : true);
    final sortedSongs = _applySort(state.allSongs, option, asc);
    state = state.copyWith(
      sortOption: option,
      sortAscending: asc,
      allSongs: sortedSongs,
    );
  }

  List<AudioTrack> _applySort(List<AudioTrack> songs, SortOption option, bool ascending) {
    final list = List<AudioTrack>.from(songs);
    list.sort((a, b) {
      int cmp = 0;
      switch (option) {
        case SortOption.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortOption.artist:
          cmp = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case SortOption.album:
          cmp = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          break;
        case SortOption.duration:
          cmp = a.durationMs.compareTo(b.durationMs);
          break;
        case SortOption.dateAdded:
          final aDate = a.dateAdded ?? 0;
          final bDate = b.dateAdded ?? 0;
          cmp = aDate.compareTo(bDate);
          break;
        case SortOption.trackNumber:
          final aNum = a.trackNumber ?? 0;
          final bNum = b.trackNumber ?? 0;
          cmp = aNum.compareTo(bNum);
          break;
      }
      return ascending ? cmp : -cmp;
    });
    return list;
  }

  List<AlbumModel> _groupAlbums(List<AudioTrack> songs) {
    final Map<String, List<AudioTrack>> albumMap = {};
    for (final song in songs) {
      final key = '${song.album}_${song.artist}';
      albumMap.putIfAbsent(key, () => []).add(song);
    }

    return albumMap.entries.map((entry) {
      final first = entry.value.first;
      return AlbumModel(
        title: first.album,
        artist: first.artist,
        albumId: first.albumId,
        tracks: entry.value,
      );
    }).toList();
  }

  List<ArtistModel> _groupArtists(List<AudioTrack> songs) {
    final Map<String, List<AudioTrack>> artistMap = {};
    for (final song in songs) {
      artistMap.putIfAbsent(song.artist, () => []).add(song);
    }

    return artistMap.entries.map((entry) {
      return ArtistModel(
        name: entry.key,
        tracks: entry.value,
      );
    }).toList();
  }

  List<FolderModel> _groupFolders(List<AudioTrack> songs) {
    final Map<String, List<AudioTrack>> folderMap = {};
    for (final song in songs) {
      if (song.path.isNotEmpty) {
        final dir = p.dirname(song.path);
        folderMap.putIfAbsent(dir, () => []).add(song);
      }
    }

    return folderMap.entries.map((entry) {
      return FolderModel.fromPath(entry.key, entry.value);
    }).toList();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}

final libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});
