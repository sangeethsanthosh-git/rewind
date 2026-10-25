import 'package:flutter/material.dart';

enum AppThemeMode { dark, light, system }

enum AppBackgroundTheme {
  obsidian,
  vinylCharcoal,
  tokyoBurgundy,
  midnightIndigo,
  walnutBronze,
  slateMinimal,
}

enum MechanicalSoundProfile { soft, classic, heavy }

class AppSettings {
  final AppThemeMode themeMode;
  final AppBackgroundTheme backgroundTheme;
  final String? customBackgroundImagePath;
  final bool useSongBannerCanvas;
  final double backgroundDimLevel;
  final double backgroundBlurSigma;
  final int accentColorValue;
  final bool enableAnimations;
  final bool gaplessPlayback;
  final List<String> excludedFolders;
  final int? sleepTimerMinutes;
  final DateTime? sleepTimerEndTime;

  // Walkman & Mechanical Experience Settings
  final bool enableMechanicalSounds;
  final bool enableCassetteSounds;
  final bool enableMotorAmbience;
  final bool enableHaptics;
  final double uiSoundVolume;
  final MechanicalSoundProfile soundProfile;
  final bool reducedAnimation;
  final bool walkmanMode;

  Color get accentColor => Color(accentColorValue);

  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.backgroundTheme = AppBackgroundTheme.obsidian,
    this.customBackgroundImagePath,
    this.useSongBannerCanvas = true,
    this.backgroundDimLevel = 0.50,
    this.backgroundBlurSigma = 6.0,
    this.accentColorValue = 0xFFFF5E36, // Default Neon Orange
    this.enableAnimations = true,
    this.gaplessPlayback = true,
    this.excludedFolders = const ['Ringtones', 'Notifications', 'Alarms', 'WhatsApp Audio'],
    this.sleepTimerMinutes,
    this.sleepTimerEndTime,
    this.enableMechanicalSounds = true,
    this.enableCassetteSounds = true,
    this.enableMotorAmbience = false,
    this.enableHaptics = true,
    this.uiSoundVolume = 0.8,
    this.soundProfile = MechanicalSoundProfile.classic,
    this.reducedAnimation = false,
    this.walkmanMode = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppBackgroundTheme? backgroundTheme,
    String? customBackgroundImagePath,
    bool clearCustomBackgroundImage = false,
    bool? useSongBannerCanvas,
    double? backgroundDimLevel,
    double? backgroundBlurSigma,
    int? accentColorValue,
    bool? enableAnimations,
    bool? gaplessPlayback,
    List<String>? excludedFolders,
    int? sleepTimerMinutes,
    DateTime? sleepTimerEndTime,
    bool clearSleepTimer = false,
    bool? enableMechanicalSounds,
    bool? enableCassetteSounds,
    bool? enableMotorAmbience,
    bool? enableHaptics,
    double? uiSoundVolume,
    MechanicalSoundProfile? soundProfile,
    bool? reducedAnimation,
    bool? walkmanMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
      customBackgroundImagePath: clearCustomBackgroundImage
          ? null
          : (customBackgroundImagePath ?? this.customBackgroundImagePath),
      useSongBannerCanvas: useSongBannerCanvas ?? this.useSongBannerCanvas,
      backgroundDimLevel: backgroundDimLevel ?? this.backgroundDimLevel,
      backgroundBlurSigma: backgroundBlurSigma ?? this.backgroundBlurSigma,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      sleepTimerMinutes: clearSleepTimer ? null : (sleepTimerMinutes ?? this.sleepTimerMinutes),
      sleepTimerEndTime: clearSleepTimer ? null : (sleepTimerEndTime ?? this.sleepTimerEndTime),
      enableMechanicalSounds: enableMechanicalSounds ?? this.enableMechanicalSounds,
      enableCassetteSounds: enableCassetteSounds ?? this.enableCassetteSounds,
      enableMotorAmbience: enableMotorAmbience ?? this.enableMotorAmbience,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      uiSoundVolume: uiSoundVolume ?? this.uiSoundVolume,
      soundProfile: soundProfile ?? this.soundProfile,
      reducedAnimation: reducedAnimation ?? this.reducedAnimation,
      walkmanMode: walkmanMode ?? this.walkmanMode,
    );
  }
}
