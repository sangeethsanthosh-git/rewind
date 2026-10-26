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
  final String walkmanChassisTheme;
  final String? walkmanCustomSkinPath;
  final String walkmanBrandingText;
  final int walkmanHotlineColorValue;

  Color get accentColor => Color(accentColorValue);
  Color get walkmanHotlineColor => Color(walkmanHotlineColorValue);

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
    this.walkmanChassisTheme = 'classicBlue',
    this.walkmanCustomSkinPath,
    this.walkmanBrandingText = 'SONY',
    this.walkmanHotlineColorValue = 0xFFF08A1C,
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
    String? walkmanChassisTheme,
    String? walkmanCustomSkinPath,
    bool clearWalkmanCustomSkin = false,
    String? walkmanBrandingText,
    int? walkmanHotlineColorValue,
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
      walkmanChassisTheme: walkmanChassisTheme ?? this.walkmanChassisTheme,
      walkmanCustomSkinPath: clearWalkmanCustomSkin
          ? null
          : (walkmanCustomSkinPath ?? this.walkmanCustomSkinPath),
      walkmanBrandingText: walkmanBrandingText ?? this.walkmanBrandingText,
      walkmanHotlineColorValue: walkmanHotlineColorValue ?? this.walkmanHotlineColorValue,
    );
  }

  Map<String, String> toPersistenceMap() {
    return {
      'customBackgroundImagePath': customBackgroundImagePath ?? '',
      'useSongBannerCanvas': useSongBannerCanvas ? '1' : '0',
      'backgroundDimLevel': backgroundDimLevel.toString(),
      'backgroundBlurSigma': backgroundBlurSigma.toString(),
      'accentColorValue': accentColorValue.toString(),
      'enableMechanicalSounds': enableMechanicalSounds ? '1' : '0',
      'enableCassetteSounds': enableCassetteSounds ? '1' : '0',
      'enableMotorAmbience': enableMotorAmbience ? '1' : '0',
      'enableHaptics': enableHaptics ? '1' : '0',
      'uiSoundVolume': uiSoundVolume.toString(),
      'soundProfile': soundProfile.name,
      'reducedAnimation': reducedAnimation ? '1' : '0',
      'walkmanMode': walkmanMode ? '1' : '0',
      'walkmanChassisTheme': walkmanChassisTheme,
      'walkmanCustomSkinPath': walkmanCustomSkinPath ?? '',
      'walkmanBrandingText': walkmanBrandingText,
      'walkmanHotlineColorValue': walkmanHotlineColorValue.toString(),
      'gaplessPlayback': gaplessPlayback ? '1' : '0',
      'excludedFolders': excludedFolders.join('|'),
    };
  }

  factory AppSettings.fromPersistenceMap(Map<String, String> map) {
    const defaults = AppSettings();
    final customBg = map['customBackgroundImagePath'];
    final customSkin = map['walkmanCustomSkinPath'];
    final foldersStr = map['excludedFolders'];

    return AppSettings(
      customBackgroundImagePath: (customBg == null || customBg.isEmpty) ? null : customBg,
      walkmanCustomSkinPath: (customSkin == null || customSkin.isEmpty) ? null : customSkin,
      useSongBannerCanvas: map.containsKey('useSongBannerCanvas')
          ? map['useSongBannerCanvas'] == '1'
          : defaults.useSongBannerCanvas,
      backgroundDimLevel: map.containsKey('backgroundDimLevel')
          ? (double.tryParse(map['backgroundDimLevel']!) ?? defaults.backgroundDimLevel)
          : defaults.backgroundDimLevel,
      backgroundBlurSigma: map.containsKey('backgroundBlurSigma')
          ? (double.tryParse(map['backgroundBlurSigma']!) ?? defaults.backgroundBlurSigma)
          : defaults.backgroundBlurSigma,
      accentColorValue: map.containsKey('accentColorValue')
          ? (int.tryParse(map['accentColorValue']!) ?? defaults.accentColorValue)
          : defaults.accentColorValue,
      enableMechanicalSounds: map.containsKey('enableMechanicalSounds')
          ? map['enableMechanicalSounds'] == '1'
          : defaults.enableMechanicalSounds,
      enableCassetteSounds: map.containsKey('enableCassetteSounds')
          ? map['enableCassetteSounds'] == '1'
          : defaults.enableCassetteSounds,
      enableMotorAmbience: map.containsKey('enableMotorAmbience')
          ? map['enableMotorAmbience'] == '1'
          : defaults.enableMotorAmbience,
      enableHaptics: map.containsKey('enableHaptics')
          ? map['enableHaptics'] == '1'
          : defaults.enableHaptics,
      uiSoundVolume: map.containsKey('uiSoundVolume')
          ? (double.tryParse(map['uiSoundVolume']!) ?? defaults.uiSoundVolume)
          : defaults.uiSoundVolume,
      soundProfile: map.containsKey('soundProfile')
          ? MechanicalSoundProfile.values.firstWhere(
              (p) => p.name == map['soundProfile'],
              orElse: () => defaults.soundProfile,
            )
          : defaults.soundProfile,
      reducedAnimation: map.containsKey('reducedAnimation')
          ? map['reducedAnimation'] == '1'
          : defaults.reducedAnimation,
      walkmanMode: map.containsKey('walkmanMode')
          ? map['walkmanMode'] == '1'
          : defaults.walkmanMode,
      walkmanChassisTheme: map.containsKey('walkmanChassisTheme')
          ? map['walkmanChassisTheme']!
          : defaults.walkmanChassisTheme,
      walkmanBrandingText: map.containsKey('walkmanBrandingText')
          ? map['walkmanBrandingText']!
          : defaults.walkmanBrandingText,
      walkmanHotlineColorValue: map.containsKey('walkmanHotlineColorValue')
          ? (int.tryParse(map['walkmanHotlineColorValue']!) ?? defaults.walkmanHotlineColorValue)
          : defaults.walkmanHotlineColorValue,
      gaplessPlayback: map.containsKey('gaplessPlayback')
          ? map['gaplessPlayback'] == '1'
          : defaults.gaplessPlayback,
      excludedFolders: (foldersStr != null && foldersStr.isNotEmpty)
          ? foldersStr.split('|')
          : defaults.excludedFolders,
    );
  }
}
