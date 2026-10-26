import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spool/core/database/app_database.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/settings/domain/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  Timer? _sleepTimer;

  SettingsNotifier(this._ref) : super(const AppSettings()) {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final db = AppDatabase.instance;
      final savedSettings = await db.getAllSettings();
      if (!mounted) return;
      if (savedSettings.isNotEmpty) {
        state = AppSettings.fromPersistenceMap(savedSettings);
      }
    } catch (e) {
      debugPrint('Error loading settings from database: $e');
    }
  }

  Future<void> _persistSettings() async {
    try {
      final db = AppDatabase.instance;
      final map = state.toPersistenceMap();
      await db.saveAllSettings(map);
    } catch (e) {
      debugPrint('Error saving settings to database: $e');
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persistSettings();
  }

  void setBackgroundTheme(AppBackgroundTheme theme) {
    state = state.copyWith(backgroundTheme: theme);
    _persistSettings();
  }

  void setCustomBackgroundImage(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomBackgroundImage: true);
    } else {
      state = state.copyWith(customBackgroundImagePath: path);
    }
    _persistSettings();
  }

  void setUseSongBannerCanvas(bool enabled) {
    state = state.copyWith(useSongBannerCanvas: enabled);
    _persistSettings();
  }

  void setBackgroundDimLevel(double level) {
    state = state.copyWith(backgroundDimLevel: level.clamp(0.1, 0.95));
    _persistSettings();
  }

  void setBackgroundBlur(double sigma) {
    state = state.copyWith(backgroundBlurSigma: sigma.clamp(0.0, 30.0));
    _persistSettings();
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColorValue: color.toARGB32());
    _persistSettings();
  }

  void toggleAnimations(bool enabled) {
    state = state.copyWith(enableAnimations: enabled);
    _persistSettings();
  }

  void toggleGapless(bool enabled) {
    state = state.copyWith(gaplessPlayback: enabled);
    _persistSettings();
  }

  void setMechanicalSounds(bool enabled) {
    state = state.copyWith(enableMechanicalSounds: enabled);
    _persistSettings();
  }

  void setCassetteSounds(bool enabled) {
    state = state.copyWith(enableCassetteSounds: enabled);
    _persistSettings();
  }

  void setMotorAmbience(bool enabled) {
    state = state.copyWith(enableMotorAmbience: enabled);
    _persistSettings();
  }

  void setHaptics(bool enabled) {
    state = state.copyWith(enableHaptics: enabled);
    _persistSettings();
  }

  void setUiSoundVolume(double volume) {
    state = state.copyWith(uiSoundVolume: volume.clamp(0.0, 1.0));
    _persistSettings();
  }

  void setSoundProfile(MechanicalSoundProfile profile) {
    state = state.copyWith(soundProfile: profile);
    _persistSettings();
  }

  void setReducedAnimation(bool enabled) {
    state = state.copyWith(reducedAnimation: enabled);
    _persistSettings();
  }

  void setWalkmanMode(bool enabled) {
    state = state.copyWith(walkmanMode: enabled);
    _persistSettings();
  }

  void setWalkmanChassisTheme(String theme) {
    state = state.copyWith(walkmanChassisTheme: theme);
    _persistSettings();
  }

  void setWalkmanBrandingText(String text) {
    state = state.copyWith(walkmanBrandingText: text.trim().isEmpty ? 'SONY' : text.trim());
    _persistSettings();
  }

  void setWalkmanHotlineColor(Color color) {
    state = state.copyWith(walkmanHotlineColorValue: color.toARGB32());
    _persistSettings();
  }

  void addExcludedFolder(String folder) {
    if (!state.excludedFolders.contains(folder)) {
      state = state.copyWith(
        excludedFolders: [...state.excludedFolders, folder],
      );
      _persistSettings();
    }
  }

  void removeExcludedFolder(String folder) {
    state = state.copyWith(
      excludedFolders: state.excludedFolders.where((f) => f != folder).toList(),
    );
    _persistSettings();
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
