import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:spool/core/database/app_database.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/collections/domain/playlist_model.dart';

class CollectionsState {
  final List<PlaylistModel> playlists;
  final List<AudioTrack> favorites;
  final List<AudioTrack> recentlyPlayed;
  final List<AudioTrack> mostPlayed;
  final bool isLoading;

  const CollectionsState({
    this.playlists = const [],
    this.favorites = const [],
    this.recentlyPlayed = const [],
    this.mostPlayed = const [],
    this.isLoading = false,
  });

  CollectionsState copyWith({
    List<PlaylistModel>? playlists,
    List<AudioTrack>? favorites,
    List<AudioTrack>? recentlyPlayed,
    List<AudioTrack>? mostPlayed,
    bool? isLoading,
  }) {
    return CollectionsState(
      playlists: playlists ?? this.playlists,
      favorites: favorites ?? this.favorites,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CollectionsNotifier extends StateNotifier<CollectionsState> {
  final _uuid = const Uuid();

  CollectionsNotifier() : super(const CollectionsState()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    state = state.copyWith(isLoading: true);
    final playlistsRaw = await AppDatabase.instance.getPlaylists();
    final playlists = playlistsRaw.map((e) => PlaylistModel.fromMap(e)).toList();

    final favorites = await AppDatabase.instance.getFavoriteSongs();
    final recentlyPlayed = await AppDatabase.instance.getRecentlyPlayed();
    final mostPlayed = await AppDatabase.instance.getMostPlayed();

    state = state.copyWith(
      playlists: playlists,
      favorites: favorites,
      recentlyPlayed: recentlyPlayed,
      mostPlayed: mostPlayed,
      isLoading: false,
    );
  }

  Future<String> createPlaylist(String name, int colorAccent, [String? description]) async {
    final id = _uuid.v4();
    await AppDatabase.instance.createPlaylist(id, name, colorAccent, description);
    await loadCollections();
    return id;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await AppDatabase.instance.deletePlaylist(playlistId);
    await loadCollections();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await AppDatabase.instance.addSongToPlaylist(playlistId, songId);
    await loadCollections();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await AppDatabase.instance.removeSongFromPlaylist(playlistId, songId);
    await loadCollections();
  }

  Future<List<AudioTrack>> getPlaylistSongs(String playlistId) async {
    return await AppDatabase.instance.getPlaylistSongs(playlistId);
  }

  Future<void> toggleFavorite(AudioTrack track) async {
    final newStatus = !track.isFavorite;
    await AppDatabase.instance.toggleFavorite(track.id, newStatus);
    await loadCollections();
  }

  Future<void> clearHistory() async {
    await AppDatabase.instance.clearHistory();
    await loadCollections();
  }
}

final collectionsNotifierProvider =
    StateNotifierProvider<CollectionsNotifier, CollectionsState>((ref) {
  return CollectionsNotifier();
});
