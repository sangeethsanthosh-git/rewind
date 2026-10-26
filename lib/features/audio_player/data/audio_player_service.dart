import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../core/database/app_database.dart';
import '../domain/audio_track.dart';
import '../domain/playback_state.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<SpoolPlaybackState>.broadcast();

  SpoolPlaybackState _state = const SpoolPlaybackState();
  bool _hasPlaylist = false;
  int _loadGeneration = 0;
  bool _disposed = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Stream<SpoolPlaybackState> get stateStream => _stateController.stream;
  SpoolPlaybackState get currentState => _state;
  AudioPlayer get rawPlayer => _player;

  AudioPlayerService() {
    _initAudioSession();
    _listenPlayerEvents();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      if (_disposed) return;

      _subscriptions.add(
        session.becomingNoisyEventStream.listen((_) {
          pause();
        }),
      );

      _subscriptions.add(
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(0.4);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                pause();
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(1.0);
                break;
              case AudioInterruptionType.pause:
                resume();
                break;
              case AudioInterruptionType.unknown:
                break;
            }
          }
        }),
      );
    } catch (_) {}
  }

  void _listenPlayerEvents() {
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final isBuffering =
            playerState.processingState == ProcessingState.buffering ||
            playerState.processingState == ProcessingState.loading;

        _updateState(
          _state.copyWith(
            isPlaying:
                isPlaying &&
                playerState.processingState != ProcessingState.completed,
            isBuffering: isBuffering,
          ),
        );
      }),
    );

    _subscriptions.add(
      _player.positionStream.listen((position) {
        _updateState(_state.copyWith(position: position));
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null) {
          _updateState(_state.copyWith(duration: duration));
        }
      }),
    );

    _subscriptions.add(
      _player.bufferedPositionStream.listen((buffered) {
        _updateState(_state.copyWith(bufferedPosition: buffered));
      }),
    );

    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (index != null && index >= 0 && index < _state.queue.length) {
          final track = _state.queue[index];
          _updateState(
            _state.copyWith(
              currentIndex: index,
              currentTrack: track,
              clearError: true,
            ),
          );
          AppDatabase.instance.recordPlay(track.id);
        }
      }),
    );
  }

  Uri? _getArtworkUri(AudioTrack track) {
    if (track.customArtPath != null && track.customArtPath!.isNotEmpty) {
      return Uri.file(track.customArtPath!);
    }
    if (track.albumId != null) {
      return Uri.parse(
        'content://media/external/audio/albumart/${track.albumId}',
      );
    }
    return null;
  }

  AudioSource _createAudioSource(AudioTrack track) {
    final source = track.uri.trim();
    final parsed = Uri.tryParse(source);
    final uri =
        parsed != null &&
            const ['content', 'http', 'https', 'file'].contains(parsed.scheme)
        ? parsed
        : Uri.file(track.path.isNotEmpty ? track.path : source);
    if (source.isEmpty && track.path.isEmpty) {
      throw StateError(
        'No audio file is attached to this song. Scan your music library.',
      );
    }

    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: track.id,
        album: track.album,
        title: track.title,
        artist: track.artist,
        artUri: _getArtworkUri(track),
        duration: track.durationMs > 0
            ? Duration(milliseconds: track.durationMs)
            : null,
      ),
    );
  }

  Future<void> playTrack(AudioTrack track, {List<AudioTrack>? queue}) async {
    final generation = ++_loadGeneration;
    try {
      final newQueue = List<AudioTrack>.of(queue ?? [track]);
      if (!newQueue.any((item) => item.id == track.id)) {
        newQueue.insert(0, track);
      }
      final targetIndex = newQueue.indexWhere((t) => t.id == track.id);
      final initialIndex = targetIndex >= 0 ? targetIndex : 0;

      final audioSources = newQueue.map((t) => _createAudioSource(t)).toList();

      _updateState(
        _state.copyWith(
          isPlaying: false,
          isBuffering: true,
          position: Duration.zero,
          duration: Duration(milliseconds: track.durationMs),
          bufferedPosition: Duration.zero,
          queue: List.unmodifiable(newQueue),
          currentIndex: initialIndex,
          currentTrack: newQueue[initialIndex],
          clearError: true,
        ),
      );

      await _player.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );

      if (generation != _loadGeneration || _disposed) return;
      _hasPlaylist = true;
      unawaited(_startPlayback(generation));
    } on PlayerInterruptedException {
      // A newer selection superseded this load. It is not a file error.
      if (generation == _loadGeneration && !_disposed) {
        _updateState(_state.copyWith(isBuffering: false));
      }
    } on PlayerException catch (e) {
      if (generation != _loadGeneration || _disposed) return;
      _updateState(
        _state.copyWith(
          errorMessage:
              'Playback failed (${e.message}). Codec or format may not be supported on this device.',
          isPlaying: false,
          isBuffering: false,
        ),
      );
    } catch (e) {
      if (generation != _loadGeneration || _disposed) return;
      _updateState(
        _state.copyWith(
          errorMessage: 'Unable to open file: $e',
          isPlaying: false,
          isBuffering: false,
        ),
      );
    }
  }

  Future<void> _startPlayback(int generation) async {
    try {
      await _player.play();
    } on PlayerInterruptedException {
      // Replaced by a new source.
    } catch (error) {
      if (generation == _loadGeneration && !_disposed) {
        _updateState(
          _state.copyWith(
            isPlaying: false,
            isBuffering: false,
            errorMessage: 'Playback failed: $error',
          ),
        );
      }
    }
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _state.queue.length) return;
    try {
      await _player.seek(Duration.zero, index: index);
      unawaited(_startPlayback(_loadGeneration));
    } catch (e) {
      _updateState(_state.copyWith(errorMessage: 'Playback error: $e'));
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    if (_state.currentTrack != null) {
      if (_state.errorMessage != null) {
        await playTrack(_state.currentTrack!, queue: _state.queue);
        return;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      _updateState(_state.copyWith(clearError: true));
      unawaited(_startPlayback(_loadGeneration));
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_state.repeatMode == LoopMode.all && _state.queue.isNotEmpty) {
      await playAt(0);
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> toggleShuffle() async {
    final nextMode = !_state.isShuffleEnabled;
    await _player.setShuffleModeEnabled(nextMode);
    if (nextMode) {
      await _player.shuffle();
    }
    _updateState(_state.copyWith(isShuffleEnabled: nextMode));
  }

  Future<void> toggleRepeat() async {
    LoopMode nextMode;
    switch (_state.repeatMode) {
      case LoopMode.off:
        nextMode = LoopMode.all;
        break;
      case LoopMode.all:
        nextMode = LoopMode.one;
        break;
      case LoopMode.one:
        nextMode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(nextMode);
    _updateState(_state.copyWith(repeatMode: nextMode));
  }

  Future<void> addToQueue(AudioTrack track) async {
    final updatedQueue = List<AudioTrack>.from(_state.queue)..add(track);
    if (_hasPlaylist) {
      await _player.addAudioSource(_createAudioSource(track));
    }
    _updateState(_state.copyWith(queue: updatedQueue));
  }

  Future<void> playNext(AudioTrack track) async {
    final insertIndex = _state.currentIndex + 1;
    final updatedQueue = List<AudioTrack>.from(_state.queue);
    if (insertIndex <= updatedQueue.length) {
      updatedQueue.insert(insertIndex, track);
      if (_hasPlaylist) {
        await _player.insertAudioSource(insertIndex, _createAudioSource(track));
      }
    } else {
      updatedQueue.add(track);
      if (_hasPlaylist) {
        await _player.addAudioSource(_createAudioSource(track));
      }
    }
    _updateState(_state.copyWith(queue: updatedQueue));
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _state.queue.length) return;
    final updatedQueue = List<AudioTrack>.from(_state.queue)..removeAt(index);
    if (_hasPlaylist) {
      await _player.removeAudioSourceAt(index);
    }
    _updateState(_state.copyWith(queue: updatedQueue));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _updateState(_state.copyWith(speed: speed));
  }

  void _updateState(SpoolPlaybackState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _disposed = true;
    _loadGeneration++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _player.dispose();
    _stateController.close();
  }
}
