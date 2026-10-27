import 'package:flutter/material.dart';
import '../../features/settings/domain/app_settings.dart';

class ThemePalette {
  final AppBackgroundTheme theme;
  final String displayName;
  final String description;
  final Color background;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color previewColor;

  const ThemePalette({
    required this.theme,
    required this.displayName,
    required this.description,
    required this.background,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.previewColor,
  });
}

class AppColors {
  // Deep immersive backgrounds
  static const Color obsidian = Color(0xFF09090B);
  static const Color darkCharcoal = Color(0xFF141417);
  static const Color surfaceCard = Color(0xFF1C1C21);
  static const Color surfaceElevated = Color(0xFF26262D);
  static const Color borderSubtle = Color(0xFF32323A);

  // Vintage analog paper / cassette tones
  static const Color cassetteCream = Color(0xFFEBE6DC);
  static const Color parchment = Color(0xFFF4EFE6);
  static const Color vintagePaper = Color(0xFFDDD6C7);
  static const Color analogDark = Color(0xFF1E1D1B);

  // Vibrant analog accents
  static const Color neonOrange = Color(0xFFFF5E36);
  static const Color tapeAmber = Color(0xFFFF9500);
  static const Color vinylRed = Color(0xFFE53935);
  static const Color vhsCyan = Color(0xFF00C7BE);
  static const Color spoolGold = Color(0xFFFFD60A);
  static const Color tapeGreen = Color(0xFF34C759);

  // Text colors
  static const Color textPrimary = Color(0xFFF8F8F8);
  static const Color textSecondary = Color(0xFFA0A0AB);
  static const Color textMuted = Color(0xFF6B6B76);
  static const Color textOnCream = Color(0xFF18181A);

  // Spine colors for floating albums (inspired by reference image 2)
  static const List<Color> spinePalette = [
    Color(0xFFE55039), // Tangerine Red
    Color(0xFF4A69BD), // Classic Blue
    Color(0xFF78E08F), // Brat Green
    Color(0xFFFA983A), // Sunset Orange
    Color(0xFF6A89CC), // Slate Blue
    Color(0xFFE58E26), // Warm Honey
    Color(0xFF38ADA9), // Vintage Cyan
    Color(0xFFB8E994), // Washed Lime
    Color(0xFFEA8685), // Soft Coral
    Color(0xFF596275), // Charcoal Blue
  ];

  static const List<ThemePalette> availablePalettes = [
    ThemePalette(
      theme: AppBackgroundTheme.obsidian,
      displayName: 'Obsidian Black',
      description: 'Studio pitch black with subtle warm undertones',
      background: Color(0xFF09090B),
      surfaceCard: Color(0xFF16161B),
      surfaceElevated: Color(0xFF22222A),
      borderSubtle: Color(0xFF2C2C36),
      previewColor: Color(0xFF09090B),
    ),
    ThemePalette(
      theme: AppBackgroundTheme.vinylCharcoal,
      displayName: 'Vinyl Charcoal',
      description: 'Dark acetate groove gray from 70s pressed LPs',
      background: Color(0xFF141519),
      surfaceCard: Color(0xFF1E2026),
      surfaceElevated: Color(0xFF282B33),
      borderSubtle: Color(0xFF353944),
      previewColor: Color(0xFF202228),
    ),
    ThemePalette(
      theme: AppBackgroundTheme.tokyoBurgundy,
      displayName: 'Tokyo 1984',
      description: 'Japanese vintage cassette deck deep wine burgundy',
      background: Color(0xFF170D12),
      surfaceCard: Color(0xFF26151E),
      surfaceElevated: Color(0xFF331D28),
      borderSubtle: Color(0xFF452737),
      previewColor: Color(0xFF331D28),
    ),
    ThemePalette(
      theme: AppBackgroundTheme.midnightIndigo,
      displayName: 'Midnight Indigo',
      description: 'Late-night sound engineering console navy',
      background: Color(0xFF0B101E),
      surfaceCard: Color(0xFF141C30),
      surfaceElevated: Color(0xFF1D2845),
      borderSubtle: Color(0xFF2A3A60),
      previewColor: Color(0xFF141C30),
    ),
    ThemePalette(
      theme: AppBackgroundTheme.walnutBronze,
      displayName: 'Hi-Fi Walnut',
      description: 'Rich warm woodgrain & brass amplifier finish',
      background: Color(0xFF16120E),
      surfaceCard: Color(0xFF241D17),
      surfaceElevated: Color(0xFF332A21),
      borderSubtle: Color(0xFF45382D),
      previewColor: Color(0xFF332A21),
    ),
    ThemePalette(
      theme: AppBackgroundTheme.slateMinimal,
      displayName: 'Nordic Slate',
      description: 'Clean industrial tape transport anodized slate',
      background: Color(0xFF12161A),
      surfaceCard: Color(0xFF1C2228),
      surfaceElevated: Color(0xFF262E36),
      borderSubtle: Color(0xFF36414D),
      previewColor: Color(0xFF262E36),
    ),
  ];

  static ThemePalette getThemePalette(AppBackgroundTheme theme) {
    return availablePalettes.firstWhere(
      (p) => p.theme == theme,
      orElse: () => availablePalettes.first,
    );
  }
}
