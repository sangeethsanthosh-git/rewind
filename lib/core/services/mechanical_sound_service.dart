import 'dart:async';
import 'package:flutter/services.dart';
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
  static const MethodChannel _nativeChannel = MethodChannel('com.antigravity.rewind/sound_effects');

  int _lastPlayTimeMs = 0;
  bool _isMotorHumming = false;

  MechanicalSoundService._init();

  Future<void> playMechanicalSound(
    MechanicalSoundType type, {
    required AppSettings settings,
  }) async {
    // Check if mechanical feedback is enabled
    if (!settings.enableMechanicalSounds && !settings.enableHaptics) {
      return;
    }

    if ((type == MechanicalSoundType.cassetteInsert ||
            type == MechanicalSoundType.cassetteEject) &&
        !settings.enableCassetteSounds) {
      _triggerHaptic(type, settings);
      return;
    }

    // Trigger tactile haptic feedback
    _triggerHaptic(type, settings);

    if (settings.enableMechanicalSounds) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPlayTimeMs < 40 && type == MechanicalSoundType.skipClick) {
        return;
      }
      _lastPlayTimeMs = now;

      final soundName = _getSoundName(type);
      final double volume = settings.uiSoundVolume.clamp(0.0, 1.0);

      try {
        final played = await _nativeChannel.invokeMethod<bool>('playSound', {
          'name': soundName,
          'volume': volume,
        });

        if (played != true) {
          SystemSound.play(SystemSoundType.click);
        }
      } catch (_) {
        // Fallback for non-Android platforms or tests
        try {
          SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    }
  }

  String _getSoundName(MechanicalSoundType type) {
    switch (type) {
      case MechanicalSoundType.playClack:
        return 'play_clack';
      case MechanicalSoundType.pauseClick:
        return 'pause_click';
      case MechanicalSoundType.skipClick:
        return 'skip_click';
      case MechanicalSoundType.cassetteInsert:
        return 'cassette_insert';
      case MechanicalSoundType.cassetteEject:
        return 'cassette_eject';
      case MechanicalSoundType.doorLatch:
        return 'door_latch';
    }
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
      if (_isMotorHumming) {
        _isMotorHumming = false;
        try {
          await _nativeChannel.invokeMethod('stopMotorHum');
        } catch (_) {}
      }
      return;
    }

    if (isPlayingMusic && !_isMotorHumming) {
      _isMotorHumming = true;
      try {
        await _nativeChannel.invokeMethod('startMotorHum', {
          'volume': (settings.uiSoundVolume * 0.35).clamp(0.05, 0.6),
        });
      } catch (_) {}
    }
  }

  void dispose() {
    if (_isMotorHumming) {
      _nativeChannel.invokeMethod('stopMotorHum').catchError((_) => null);
      _isMotorHumming = false;
    }
  }
}
