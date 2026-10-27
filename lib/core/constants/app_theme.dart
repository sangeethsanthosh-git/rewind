import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized Material 3 Design System for Rewind.
/// Combines modern Android Material You standards with Rewind's iconic
/// dark retro Walkman physical aesthetic.
class AppTheme {
  /// Primary Dark Experience (Default)
  static ThemeData getTheme({Color accentColor = AppColors.brandGreen}) {
    return getDarkTheme(accentColor: accentColor);
  }

  static ThemeData getDarkTheme({Color accentColor = AppColors.brandGreen}) {
    final bool isAccentLight = accentColor.computeLuminance() > 0.55;
    final Color onAccent = isAccentLight ? const Color(0xFF101115) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      primaryColor: accentColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: onAccent,
        primaryContainer: accentColor.withAlpha(55),
        onPrimaryContainer: accentColor,
        secondary: accentColor,
        onSecondary: onAccent,
        secondaryContainer: AppColors.surfaceElevated,
        onSecondaryContainer: AppColors.textPrimary,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textPrimary,
        surfaceContainerLowest: AppColors.obsidian,
        surfaceContainerLow: AppColors.darkCharcoal,
        surfaceContainer: AppColors.surfaceCard,
        surfaceContainerHigh: AppColors.surfaceElevated,
        surfaceContainerHighest: const Color(0xFF2C2C36),
        outline: AppColors.borderSubtle,
        outlineVariant: const Color(0xFF24242C),
        error: AppColors.vinylRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCharcoal,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        titleTextStyle: AppTypography.displaySmall.copyWith(fontSize: 18, color: Colors.white),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentColor.withAlpha(120), width: 1.0),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceCard),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCharcoal,
        elevation: 4,
        indicatorColor: accentColor.withAlpha(45),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTypography.monoSmall.copyWith(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? accentColor : AppColors.textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCharcoal,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedColor: accentColor.withAlpha(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        labelStyle: AppTypography.monoSmall.copyWith(fontSize: 11),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: AppColors.borderSubtle,
        thumbColor: accentColor,
        overlayColor: accentColor.withAlpha(50),
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: accentColor,
        labelColor: accentColor,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: AppColors.borderSubtle,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accentColor : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor.withAlpha(120)
                : AppColors.surfaceElevated),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: onAccent,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
        ),
        textStyle: AppTypography.monoSmall.copyWith(color: Colors.white, fontSize: 11),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withAlpha(80),
        selectionHandleColor: accentColor,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
      ),
    );
  }

  /// Light Experience (Vintage Parchment & Analog Cassette Paper Palette)
  static ThemeData getLightTheme({Color accentColor = const Color(0xFF15803D)}) {
    const Color paperBg = Color(0xFFF7F5EE);
    const Color paperCard = Color(0xFFECE7DB);
    const Color paperElevated = Color(0xFFE2DBD0);
    const Color paperBorder = Color(0xFFCCC5B8);
    const Color darkInk = Color(0xFF18181A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paperBg,
      primaryColor: accentColor,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        onPrimary: Colors.white,
        primaryContainer: accentColor.withAlpha(45),
        onPrimaryContainer: accentColor,
        secondary: accentColor,
        onSecondary: Colors.white,
        surface: paperCard,
        onSurface: darkInk,
        surfaceContainerLowest: paperBg,
        surfaceContainerLow: paperCard,
        surfaceContainer: paperCard,
        surfaceContainerHigh: paperElevated,
        surfaceContainerHighest: const Color(0xFFD5CEBE),
        outline: paperBorder,
        outlineVariant: const Color(0xFFDDD7CC),
        error: AppColors.vinylRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: darkInk, size: 24),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paperCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: paperBorder, width: 1.0),
        ),
        titleTextStyle: AppTypography.displaySmall.copyWith(fontSize: 18, color: darkInk),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: darkInk),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: paperElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: darkInk),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentColor.withAlpha(120), width: 1.0),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: paperCard,
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF6E685D),
        type: BottomNavigationBarType.fixed,
        elevation: 6,
      ),
      cardTheme: CardThemeData(
        color: paperCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: paperBorder, width: 0.8),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: paperBorder,
        thumbColor: accentColor,
        trackHeight: 3.5,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: darkInk),
        displayMedium: AppTypography.displayMedium.copyWith(color: darkInk),
        displaySmall: AppTypography.displaySmall.copyWith(color: darkInk),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: darkInk),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: darkInk),
        bodySmall: AppTypography.bodySmall.copyWith(color: const Color(0xFF5A554A)),
      ),
    );
  }

  static ThemeData get darkTheme => getDarkTheme();
  static ThemeData get lightTheme => getLightTheme();
}
