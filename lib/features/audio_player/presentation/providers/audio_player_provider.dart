import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio_player_service.dart';
import '../../domain/playback_state.dart';
import '../../domain/audio_track.dart';
import '../../../../core/database/app_database.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final playbackStateStreamProvider = StreamProvider<SpoolPlaybackState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.stateStream;
});

class PlaybackNotifier extends StateNotifier<SpoolPlaybackState> {
  final AudioPlayerService _service;
  late final StreamSubscription<SpoolPlaybackState> _subscription;

  PlaybackNotifier(this._service) : super(_service.currentState) {
    _subscription = _service.stateStream.listen((state) {
      this.state = state;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> playTrack(AudioTrack track, {List<AudioTrack>? queue}) =>
      _service.playTrack(track, queue: queue);

  Future<void> togglePlayPause() => _service.togglePlayPause();

  Future<void> pause() => _service.pause();

  Future<void> resume() => _service.resume();

  Future<void> seek(Duration position) => _service.seek(position);

  Future<void> skipToNext() => _service.skipToNext();

  Future<void> skipToPrevious() => _service.skipToPrevious();

  Future<void> toggleShuffle() => _service.toggleShuffle();

  Future<void> toggleRepeat() => _service.toggleRepeat();

  Future<void> playAt(int index) => _service.playAt(index);

  Future<void> addToQueue(AudioTrack track) => _service.addToQueue(track);

  Future<void> playNext(AudioTrack track) => _service.playNext(track);

  Future<void> removeFromQueue(int index) => _service.removeFromQueue(index);

  Future<void> setSpeed(double speed) => _service.setSpeed(speed);

  Future<void> toggleFavorite(AudioTrack track) async {
    final newStatus = !track.isFavorite;
    await AppDatabase.instance.toggleFavorite(track.id, newStatus);
    if (state.currentTrack?.id == track.id) {
      state = state.copyWith(
        currentTrack: track.copyWith(isFavorite: newStatus),
      );
    }
  }

  void updateCurrentTrackArt(String artPath) {
    if (state.currentTrack != null) {
      state = state.copyWith(
        currentTrack: state.currentTrack!.copyWith(customArtPath: artPath),
      );
    }
  }
}

final playbackNotifierProvider =
    StateNotifierProvider<PlaybackNotifier, SpoolPlaybackState>((ref) {
      final service = ref.watch(audioPlayerServiceProvider);
      return PlaybackNotifier(service);
    });
