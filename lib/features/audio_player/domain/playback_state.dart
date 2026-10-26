import 'package:just_audio/just_audio.dart';
import 'audio_track.dart';

class SpoolPlaybackState {
  final AudioTrack? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final List<AudioTrack> queue;
  final int currentIndex;
  final bool isShuffleEnabled;
  final LoopMode repeatMode;
  final String? errorMessage;
  final double speed;

  const SpoolPlaybackState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffleEnabled = false,
    this.repeatMode = LoopMode.off,
    this.errorMessage,
    this.speed = 1.0,
  });

  SpoolPlaybackState copyWith({
    AudioTrack? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    List<AudioTrack>? queue,
    int? currentIndex,
    bool? isShuffleEnabled,
    LoopMode? repeatMode,
    String? errorMessage,
    double? speed,
    bool clearError = false,
    bool clearCurrentTrack = false,
  }) {
    return SpoolPlaybackState(
      currentTrack: clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      speed: speed ?? this.speed,
    );
  }
}
