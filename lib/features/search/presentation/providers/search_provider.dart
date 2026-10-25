import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/database/app_database.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';

class SearchState {
  final String query;
  final List<AudioTrack> results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<AudioTrack>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: trimmed, isSearching: true);
    try {
      final results = await AppDatabase.instance.searchSongs(trimmed);
      state = state.copyWith(
        results: results,
        isSearching: false,
      );
    } catch (_) {
      state = state.copyWith(isSearching: false);
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});
