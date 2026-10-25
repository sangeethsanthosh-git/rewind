import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/settings/domain/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  Timer? _sleepTimer;

  SettingsNotifier(this._ref) : super(const AppSettings());

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setBackgroundTheme(AppBackgroundTheme theme) {
    state = state.copyWith(backgroundTheme: theme);
  }

  void setCustomBackgroundImage(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomBackgroundImage: true);
    } else {
      state = state.copyWith(customBackgroundImagePath: path);
    }
  }

  void setUseSongBannerCanvas(bool enabled) {
    state = state.copyWith(useSongBannerCanvas: enabled);
  }

  void setBackgroundDimLevel(double level) {
    state = state.copyWith(backgroundDimLevel: level.clamp(0.1, 0.95));
  }

  void setBackgroundBlur(double sigma) {
    state = state.copyWith(backgroundBlurSigma: sigma.clamp(0.0, 30.0));
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColorValue: color.toARGB32());
  }

  void toggleAnimations(bool enabled) {
    state = state.copyWith(enableAnimations: enabled);
  }

  void toggleGapless(bool enabled) {
    state = state.copyWith(gaplessPlayback: enabled);
  }

  void setMechanicalSounds(bool enabled) {
    state = state.copyWith(enableMechanicalSounds: enabled);
  }

  void setCassetteSounds(bool enabled) {
    state = state.copyWith(enableCassetteSounds: enabled);
  }

  void setMotorAmbience(bool enabled) {
    state = state.copyWith(enableMotorAmbience: enabled);
  }

  void setHaptics(bool enabled) {
    state = state.copyWith(enableHaptics: enabled);
  }

  void setUiSoundVolume(double volume) {
    state = state.copyWith(uiSoundVolume: volume.clamp(0.0, 1.0));
  }

  void setSoundProfile(MechanicalSoundProfile profile) {
    state = state.copyWith(soundProfile: profile);
  }

  void setReducedAnimation(bool enabled) {
    state = state.copyWith(reducedAnimation: enabled);
  }

  void setWalkmanMode(bool enabled) {
    state = state.copyWith(walkmanMode: enabled);
  }

  void addExcludedFolder(String folder) {
    if (!state.excludedFolders.contains(folder)) {
      state = state.copyWith(
        excludedFolders: [...state.excludedFolders, folder],
      );
    }
  }

  void removeExcludedFolder(String folder) {
    state = state.copyWith(
      excludedFolders: state.excludedFolders.where((f) => f != folder).toList(),
    );
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    if (minutes == null || minutes <= 0) {
      state = state.copyWith(clearSleepTimer: true);
      return;
    }

    final endTime = DateTime.now().add(Duration(minutes: minutes));
    state = state.copyWith(
      sleepTimerMinutes: minutes,
      sleepTimerEndTime: endTime,
    );

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _ref.read(audioPlayerServiceProvider).pause();
      state = state.copyWith(clearSleepTimer: true);
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});
