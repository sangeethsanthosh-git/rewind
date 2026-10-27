import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/features/library/presentation/providers/library_provider.dart';
import 'package:spool/features/collections/presentation/providers/collections_provider.dart';
import 'package:spool/features/settings/presentation/providers/settings_provider.dart';
import 'package:spool/features/settings/domain/app_settings.dart';
import 'package:spool/features/settings/presentation/screens/codec_diagnostics_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    final accentFg = settings.accentColor.computeLuminance() > 0.6 ? const Color(0xFF111116) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PREFERENCES',
          style: AppTypography.displaySmall.copyWith(fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
        children: [
          // Section: Custom Background & Canvas Wallpaper (Responsive & Blur Adjuster)
          _buildSectionHeader('CUSTOM IMAGE BACKGROUND & CANVAS'),
          _buildCard([
            // Custom Uploaded Image Wallpaper (Fully Responsive Row)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Image Wallpaper',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Upload any picture from device as full app background',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.accentColor,
                          foregroundColor: accentFg,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.add_photo_alternate_outlined, size: 16, color: accentFg),
                        label: Text(
                          settings.customBackgroundImagePath != null ? 'CHANGE' : 'UPLOAD',
                          style: AppTypography.monoSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: accentFg,
                          ),
                        ),
                        onPressed: () async {
                          final files = await FilePicker.pickFiles(type: FileType.image);
                          if (files.isNotEmpty && files.first.path != null) {
                            settingsNotifier.setCustomBackgroundImage(files.first.path);
                          }
                        },
                      ),
                    ],
                  ),
                  if (settings.customBackgroundImagePath != null &&
                      File(settings.customBackgroundImagePath!).existsSync()) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themePalette.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: settings.accentColor.withAlpha(120), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(settings.customBackgroundImagePath!),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVE CUSTOM WALLPAPER',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: settings.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.customBackgroundImagePath!.split(Platform.pathSeparator).last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.vinylRed),
                            tooltip: 'Remove Custom Image',
                            onPressed: () {
                              settingsNotifier.setCustomBackgroundImage(null);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            // Dynamic Song Banner Canvas Toggle
            SwitchListTile(
              activeThumbColor: settings.accentColor,
              title: Text('Dynamic Song Canvas', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Use active song\'s banner/artwork as an ambient backdrop canvas behind player & screens',
                style: AppTypography.bodySmall,
              ),
              value: settings.useSongBannerCanvas,
              onChanged: (val) {
                settingsNotifier.setUseSongBannerCanvas(val);
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            // Background Dimming Level
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Background Dimming', style: AppTypography.bodyMedium),
                      Text('${(settings.backgroundDimLevel * 100).round()}%',
                          style: AppTypography.monoSmall.copyWith(color: settings.accentColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.backgroundDimLevel,
                    min: 0.15,
                    max: 0.90,
                    divisions: 15,
                    activeColor: settings.accentColor,
                    inactiveColor: AppColors.borderSubtle,
                    onChanged: (val) {
                      settingsNotifier.setBackgroundDimLevel(val);
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            // Background Blur Level Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Background Blur', style: AppTypography.bodyMedium),
                      Text(
                        settings.backgroundBlurSigma < 0.5 ? 'Off (Crisp)' : '${settings.backgroundBlurSigma.round()} px',
                        style: AppTypography.monoSmall.copyWith(color: settings.accentColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.backgroundBlurSigma,
                    min: 0.0,
                    max: 25.0,
                    divisions: 25,
                    activeColor: settings.accentColor,
                    inactiveColor: AppColors.borderSubtle,
                    onChanged: (val) {
                      settingsNotifier.setBackgroundBlur(val);
                    },
                  ),
                ],
              ),
            ),
          ], themePalette),

          const SizedBox(height: 20),

          // Section: Button & Accent Color
          _buildSectionHeader('BUTTON & ACCENT COLOR'),
          _buildCard([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interactive Theme & Button Hue',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Customizes buttons, sliders, active badges, and player controls',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAccentSwatch(
                        label: 'Neon Orange',
                        color: const Color(0xFFFF5E36),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Cyber Lime',
                        color: const Color(0xFF1DF74B),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Electric Cyan',
                        color: const Color(0xFF00E5FF),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Analog Amber',
                        color: const Color(0xFFFF9500),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Vinyl Red',
                        color: const Color(0xFFE53935),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Synth Purple',
                        color: const Color(0xFFD500F9),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                      _buildAccentSwatch(
                        label: 'Studio White',
                        color: const Color(0xFFFFFFFF),
                        settings: settings,
                        settingsNotifier: settingsNotifier,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ], themePalette),

          const SizedBox(height: 20),

          // Section: Walkman & Mechanical Experience
          _buildSectionHeader('WALKMAN & MECHANICAL EXPERIENCE'),
          _buildCard([
            // Walkman Custom Skin row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Walkman Chassis Skin',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wrap the Walkman body with a custom image skin',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.accentColor,
                          foregroundColor: accentFg,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.brush_rounded, size: 16, color: accentFg),
                        label: Text(
                          settings.walkmanCustomSkinPath != null ? 'CHANGE' : 'CHOOSE',
                          style: AppTypography.monoSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: accentFg,
                          ),
                        ),
                        onPressed: () async {
                          final files = await FilePicker.pickFiles(type: FileType.image);
                          if (files.isNotEmpty && files.first.path != null) {
                            settingsNotifier.setWalkmanCustomSkin(files.first.path);
                          }
                        },
                      ),
                    ],
                  ),
                  if (settings.walkmanCustomSkinPath != null &&
                      File(settings.walkmanCustomSkinPath!).existsSync()) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themePalette.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: settings.accentColor.withAlpha(120), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(settings.walkmanCustomSkinPath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVE CHASSIS SKIN',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: settings.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.walkmanCustomSkinPath!.split(Platform.pathSeparator).last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.vinylRed),
                            tooltip: 'Remove Custom Skin',
                            onPressed: () {
                              settingsNotifier.setWalkmanCustomSkin(null);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            SwitchListTile(
              activeThumbColor: settings.accentColor,
              title: Text('Walkman Button Sounds', style: AppTypography.bodyMedium),
              subtitle: Text('Authentic mechanical clacks, latch snaps and switch clicks during tape playback', style: AppTypography.bodySmall),
              value: settings.enableMechanicalSounds,
              onChanged: (val) => settingsNotifier.setMechanicalSounds(val),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            SwitchListTile(
              activeThumbColor: settings.accentColor,
              title: Text('Motor Ambience', style: AppTypography.bodyMedium),
              subtitle: Text('Subtle analog capstan DC motor transport hum during playback', style: AppTypography.bodySmall),
              value: settings.enableMotorAmbience,
              onChanged: (val) => settingsNotifier.setMotorAmbience(val),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            SwitchListTile(
              activeThumbColor: settings.accentColor,
              title: Text('Tactile Haptic Feedback', style: AppTypography.bodyMedium),
              subtitle: Text('Physical vibration responses on key clicks and tape loading', style: AppTypography.bodySmall),
              value: settings.enableHaptics,
              onChanged: (val) => settingsNotifier.setHaptics(val),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mechanical Sound Volume', style: AppTypography.bodyMedium),
                      Text('${(settings.uiSoundVolume * 100).round()}%', style: AppTypography.monoSmall),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: settings.accentColor,
                      thumbColor: settings.accentColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: settings.uiSoundVolume,
                      onChanged: (val) => settingsNotifier.setUiSoundVolume(val),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              title: Text('Mechanical Sound Profile', style: AppTypography.bodyMedium),
              subtitle: Text(
                'Current: ${settings.soundProfile.name.toUpperCase()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.tapeAmber),
              ),
              trailing: DropdownButton<MechanicalSoundProfile>(
                value: settings.soundProfile,
                dropdownColor: AppColors.surfaceElevated,
                underline: const SizedBox(),
                items: MechanicalSoundProfile.values.map((profile) {
                  return DropdownMenuItem(
                    value: profile,
                    child: Text(
                      profile.name.toUpperCase(),
                      style: AppTypography.monoSmall.copyWith(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (profile) {
                  if (profile != null) {
                    settingsNotifier.setSoundProfile(profile);
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Library & Audio
          _buildSectionHeader('LIBRARY & SCANNING'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.sync_rounded, color: settings.accentColor),
              title: Text('Rescan Device Storage', style: AppTypography.bodyMedium),
              subtitle: Text('Search internal and external storage for audio tracks', style: AppTypography.bodySmall),
              onTap: () {
                ref.read(libraryNotifierProvider.notifier).rescan(
                  excludedFolders: settings.excludedFolders,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scanning local device storage...')),
                );
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined, color: AppColors.tapeAmber),
              title: Text('Excluded Folders', style: AppTypography.bodyMedium),
              subtitle: Text('${settings.excludedFolders.length} folders ignored (Ringtones, WhatsApp, etc.)', style: AppTypography.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              onTap: () => _showExcludedFoldersDialog(context, ref),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Playback Engine
          _buildSectionHeader('PLAYBACK & AUDIO ENGINE'),
          _buildCard([
            SwitchListTile(
              activeThumbColor: settings.accentColor,
              title: Text('Gapless Playback', style: AppTypography.bodyMedium),
              subtitle: Text('Preload audio buffers for uninterrupted transitions', style: AppTypography.bodySmall),
              value: settings.gaplessPlayback,
              onChanged: (val) => settingsNotifier.toggleGapless(val),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: AppColors.vhsCyan),
              title: Text('Audio Codec Diagnostics', style: AppTypography.bodyMedium),
              subtitle: Text('Inspect hardware and ExoPlayer format decoders', style: AppTypography.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CodecDiagnosticsScreen()),
                );
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.bedtime_outlined, color: AppColors.spoolGold),
              title: Text('Sleep Timer', style: AppTypography.bodyMedium),
              subtitle: Text(
                settings.sleepTimerMinutes != null
                    ? 'Active: Stops in ${settings.sleepTimerMinutes} minutes'
                    : 'Turn off playback automatically',
                style: AppTypography.bodySmall.copyWith(
                  color: settings.sleepTimerMinutes != null ? AppColors.spoolGold : AppColors.textMuted,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              onTap: () => _showSleepTimerDialog(context, ref),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Data & Storage
          _buildSectionHeader('PRIVACY & STORAGE'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.textSecondary),
              title: Text('Clear Playback History', style: AppTypography.bodyMedium),
              subtitle: Text('Reset play counts and recent rotation history', style: AppTypography.bodySmall),
              onTap: () async {
                await ref.read(collectionsNotifierProvider.notifier).clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playback history cleared.')),
                  );
                }
              },
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.tapeGreen),
              title: Text('100% Offline Guarantee', style: AppTypography.bodyMedium),
              subtitle: Text(
                'Rewind will never upload, transmit, or delete any of your audio files. All metadata and history reside solely on this device.',
                style: AppTypography.bodySmall.copyWith(fontSize: 11),
              ),
            ),
          ], themePalette),

          const SizedBox(height: 20),

          // Section: Developer & Support
          _buildSectionHeader('DEVELOPER & SUPPORT'),
          _buildCard([
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: settings.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: settings.accentColor.withValues(alpha: 0.4), width: 1.2),
                ),
                child: Icon(Icons.person_outline_rounded, color: settings.accentColor, size: 22),
              ),
              title: Text(
                'Sangeeth Santhosh',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                'Creator & Developer of Rewind',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDD00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFDD00).withValues(alpha: 0.5), width: 1.2),
                ),
                child: const Icon(Icons.coffee_rounded, color: Color(0xFFFFDD00), size: 20),
              ),
              title: Text(
                'Buy Me a Coffee',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'buymeacoffee.com/sangeethsanthoshsa',
                style: AppTypography.monoSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
              ),
              trailing: Icon(Icons.open_in_new_rounded, size: 18, color: settings.accentColor),
              onTap: () => _openOrCopyUrl(
                context,
                url: 'https://buymeacoffee.com/sangeethsanthoshsa',
                title: 'Buy Me a Coffee',
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                ),
                child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
              ),
              title: Text(
                'GitHub Profile & Source',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'github.com/sangeethsanthosh-git',
                style: AppTypography.monoSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
              ),
              trailing: Icon(Icons.open_in_new_rounded, size: 18, color: settings.accentColor),
              onTap: () => _openOrCopyUrl(
                context,
                url: 'https://github.com/sangeethsanthosh-git',
                title: 'GitHub',
              ),
            ),
          ], themePalette),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text('REWIND v1.0.11 \u2022 MATERIAL 3 EDITION', style: AppTypography.monoSmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('Handcrafted with Flutter \u2022 100% Offline', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title,
        style: AppTypography.monoSmall.copyWith(letterSpacing: 2, color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, [ThemePalette? palette]) {
    return Container(
      decoration: BoxDecoration(
        color: palette?.surfaceCard ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette?.borderSubtle ?? AppColors.borderSubtle, width: 0.8),
      ),
      child: Column(children: children),
    );
  }

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SET SLEEP TIMER', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              ...[15, 30, 45, 60].map((mins) {
                final isSelected = settings.sleepTimerMinutes == mins;
                return ListTile(
                  title: Text('$mins minutes', style: AppTypography.bodyMedium),
                  trailing: isSelected ? Icon(Icons.check, color: settings.accentColor) : null,
                  onTap: () {
                    ref.read(settingsNotifierProvider.notifier).setSleepTimer(mins);
                    Navigator.of(context).pop();
                  },
                );
              }),
              if (settings.sleepTimerMinutes != null)
                ListTile(
                  title: const Text('Turn Off Timer', style: TextStyle(color: AppColors.vinylRed)),
                  onTap: () {
                    ref.read(settingsNotifierProvider.notifier).setSleepTimer(null);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExcludedFoldersDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        title: Text('EXCLUDED FOLDERS', style: AppTypography.displaySmall.copyWith(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Podcasts',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: settings.accentColor),
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        ref.read(settingsNotifierProvider.notifier).addExcludedFolder(controller.text.trim());
                        controller.clear();
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...settings.excludedFolders.map((folder) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(folder, style: AppTypography.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.vinylRed),
                    onPressed: () {
                      ref.read(settingsNotifierProvider.notifier).removeExcludedFolder(folder);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentSwatch({
    required String label,
    required Color color,
    required AppSettings settings,
    required SettingsNotifier settingsNotifier,
  }) {
    final isSelected = settings.accentColor.toARGB32() == color.toARGB32();
    return InkWell(
      onTap: () => settingsNotifier.setAccentColor(color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.monoSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOrCopyUrl(BuildContext context, {required String url, required String title}) async {
    final uri = Uri.parse(url);
    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title link copied to clipboard: $url'),
            backgroundColor: AppColors.darkCharcoal,
          ),
        );
      }
    }
  }
}
