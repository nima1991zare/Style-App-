import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Luxe-minimal design language for Aura Stylist.
/// Ivory & charcoal canvas with champagne-gold accents,
/// editorial serif display type (Playfair) + clean Inter body.
class AppTheme {
  AppTheme._();

  // Brand palette
  static const gold = Color(0xFFB8934A);
  static const goldBright = Color(0xFFD4AF6A);
  static const goldSoft = Color(0xFFEADFC8);
  static const ink = Color(0xFF1E1B16);
  static const inkSoft = Color(0xFF575046);
  static const ivory = Color(0xFFFAF7F2);
  static const cream = Color(0xFFF3EEE5);
  static const linen = Color(0xFFE8E2D6);
  static const taupe = Color(0xFF8A8177);

  static const darkBg = Color(0xFF141210);
  static const darkSurface = Color(0xFF1E1B17);
  static const darkCard = Color(0xFF262220);
  static const darkLine = Color(0xFF3A342C);
  static const parchment = Color(0xFFF4EFE6);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: gold,
      onPrimary: Colors.white,
      primaryContainer: goldSoft,
      onPrimaryContainer: Color(0xFF4A3A18),
      secondary: taupe,
      onSecondary: Colors.white,
      secondaryContainer: cream,
      onSecondaryContainer: ink,
      tertiary: Color(0xFF6D2E46),
      onTertiary: Colors.white,
      error: Color(0xFF9C3B2E),
      onError: Colors.white,
      surface: ivory,
      onSurface: ink,
      surfaceContainerHighest: cream,
      surfaceContainerHigh: Color(0xFFF6F2EA),
      surfaceContainer: Color(0xFFF8F5EF),
      surfaceContainerLow: Color(0xFFFCFAF6),
      surfaceContainerLowest: Colors.white,
      onSurfaceVariant: inkSoft,
      outline: Color(0xFFB6AC9D),
      outlineVariant: linen,
      shadow: Color(0x22000000),
      scrim: Colors.black54,
      inverseSurface: ink,
      onInverseSurface: ivory,
      inversePrimary: goldBright,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: goldBright,
      onPrimary: Color(0xFF2A2007),
      primaryContainer: Color(0xFF4A3A18),
      onPrimaryContainer: goldSoft,
      secondary: Color(0xFFB6AC9D),
      onSecondary: Color(0xFF262220),
      secondaryContainer: darkCard,
      onSecondaryContainer: parchment,
      tertiary: Color(0xFFDE9DA6),
      onTertiary: Color(0xFF3B1B24),
      error: Color(0xFFE08877),
      onError: Color(0xFF3A130C),
      surface: darkBg,
      onSurface: parchment,
      surfaceContainerHighest: Color(0xFF2E2A25),
      surfaceContainerHigh: darkCard,
      surfaceContainer: Color(0xFF211E1A),
      surfaceContainerLow: darkSurface,
      surfaceContainerLowest: Color(0xFF100E0C),
      onSurfaceVariant: Color(0xFFBBB2A5),
      outline: Color(0xFF7E766A),
      outlineVariant: darkLine,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: parchment,
      onInverseSurface: ink,
      inversePrimary: gold,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: scheme.brightness, useMaterial3: true).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final serif = GoogleFonts.playfairDisplay(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    final textTheme = baseText.copyWith(
      displayLarge: serif.copyWith(fontSize: 52, height: 1.05),
      displayMedium: serif.copyWith(fontSize: 40, height: 1.1),
      displaySmall: serif.copyWith(fontSize: 32, height: 1.12),
      headlineLarge: serif.copyWith(fontSize: 28),
      headlineMedium: serif.copyWith(fontSize: 24),
      headlineSmall: serif.copyWith(fontSize: 21),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseText.labelLarge?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(letterSpacing: 0.3),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.headlineSmall,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        showDragHandle: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
    );
  }
}
