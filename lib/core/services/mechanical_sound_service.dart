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

  int _lastPlayTimeMs = 0;

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
      // Throttle duplicate clicks under 35ms to avoid congestion
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPlayTimeMs < 35 && type == MechanicalSoundType.skipClick) {
        return;
      }
      _lastPlayTimeMs = now;

      // Play system click to provide tactile audio feedback without violating
      // just_audio_background's single-instance restriction
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
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
    // No-op to preserve single AudioPlayer instance requirement of just_audio_background
  }

  void dispose() {}
}
