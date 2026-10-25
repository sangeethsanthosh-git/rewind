import 'dart:async';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spool/features/settings/domain/app_settings.dart';

enum MechanicalSoundType {
  playClack,
  pauseClick,
  skipClick,
  cassetteInsert,
  cassetteEject,
  doorLatch,
}

class MechanicalSoundService {
  static final MechanicalSoundService instance = MechanicalSoundService._init();

  final List<AudioPlayer> _playersPool = [];
  int _poolIndex = 0;
  static const int _poolSize = 3;

  AudioPlayer? _motorPlayer;
  bool _isMotorPlaying = false;
  int _lastPlayTimeMs = 0;

  MechanicalSoundService._init() {
    _initPool();
  }

  void _initPool() {
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer(
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );
      _playersPool.add(player);
    }

    _motorPlayer = AudioPlayer(
      handleAudioSessionActivation: false,
      androidApplyAudioAttributes: false,
    );
    _motorPlayer?.setLoopMode(LoopMode.all);
  }

  String _getAssetPath(MechanicalSoundType type) {
    switch (type) {
      case MechanicalSoundType.playClack:
        return 'assets/sounds/btn_play_clack.wav';
      case MechanicalSoundType.pauseClick:
        return 'assets/sounds/btn_pause_click.wav';
      case MechanicalSoundType.skipClick:
        return 'assets/sounds/btn_skip_click.wav';
      case MechanicalSoundType.cassetteInsert:
        return 'assets/sounds/cassette_insert.wav';
      case MechanicalSoundType.cassetteEject:
        return 'assets/sounds/cassette_eject.wav';
      case MechanicalSoundType.doorLatch:
        return 'assets/sounds/door_latch.wav';
    }
  }

  Future<void> playMechanicalSound(
    MechanicalSoundType type, {
    required AppSettings settings,
  }) async {
    // Check if mechanical sounds are enabled
    if (!settings.enableMechanicalSounds) {
      _triggerHaptic(type, settings);
      return;
    }

    if ((type == MechanicalSoundType.cassetteInsert ||
            type == MechanicalSoundType.cassetteEject) &&
        !settings.enableCassetteSounds) {
      _triggerHaptic(type, settings);
      return;
    }

    // Trigger immediate haptic feedback in parallel
    _triggerHaptic(type, settings);

    // Throttle duplicate clicks under 35ms to avoid sound congestion
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPlayTimeMs < 35 && type == MechanicalSoundType.skipClick) {
      return;
    }
    _lastPlayTimeMs = now;

    try {
      final player = _playersPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _poolSize;

      // Adjust volume & pitch based on selected sound profile
      double volMultiplier = 1.0;
      double speed = 1.0;
      switch (settings.soundProfile) {
        case MechanicalSoundProfile.soft:
          volMultiplier = 0.65;
          speed = 1.05;
          break;
        case MechanicalSoundProfile.classic:
          volMultiplier = 1.0;
          speed = 1.0;
          break;
        case MechanicalSoundProfile.heavy:
          volMultiplier = 1.2;
          speed = 0.95;
          break;
      }

      final finalVolume = (settings.uiSoundVolume * volMultiplier).clamp(0.0, 1.0);
      await player.setVolume(finalVolume);
      await player.setSpeed(speed);

      final assetPath = _getAssetPath(type);
      await player.setAsset(assetPath);
      await player.seek(Duration.zero);
      player.play(); // Execute without waiting
    } catch (_) {}
  }

  void _triggerHaptic(MechanicalSoundType type, AppSettings settings) {
    if (!settings.enableHaptics) return;

    switch (type) {
      case MechanicalSoundType.playClack:
      case MechanicalSoundType.pauseClick:
        HapticFeedback.mediumImpact();
        break;
      case MechanicalSoundType.skipClick:
      case MechanicalSoundType.doorLatch:
        HapticFeedback.lightImpact();
        break;
      case MechanicalSoundType.cassetteInsert:
      case MechanicalSoundType.cassetteEject:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> updateMotorAmbience({
    required bool isPlayingMusic,
    required AppSettings settings,
  }) async {
    if (!settings.enableMotorAmbience || !isPlayingMusic) {
      if (_isMotorPlaying) {
        _isMotorPlaying = false;
        await _motorPlayer?.pause();
      }
      return;
    }

    if (isPlayingMusic && !_isMotorPlaying) {
      _isMotorPlaying = true;
      try {
        final motorVolume = (settings.uiSoundVolume * 0.15).clamp(0.0, 0.4);
        await _motorPlayer?.setVolume(motorVolume);
        await _motorPlayer?.setAsset('assets/sounds/motor_hum.wav');
        _motorPlayer?.play();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final p in _playersPool) {
      p.dispose();
    }
    _motorPlayer?.dispose();
  }
}
