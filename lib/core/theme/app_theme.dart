import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Midnight Ocean — a palette born from bioluminescent seas,
/// the breath before sleep, and the quiet weight of deep water.
class AppTheme {
  // ─── The Palette ──────────────────────────────────────────────────────────

  /// The abyss — deepest background, almost black.
  static const Color void_ = Color(0xFF060A14);

  /// Midnight — primary scaffold background.
  static const Color midnight = Color(0xFF0A0E1A);

  /// Deep sea — surface / container colour.
  static const Color deepSea = Color(0xFF101625);

  /// Tide pool — card colour.
  static const Color tidePool = Color(0xFF172036);

  /// Current — elevated surface (dialogs, sheets).
  static const Color current = Color(0xFF1E2A42);

  /// Shimmer — subtle border / divider.
  static const Color shimmer = Color(0xFF253352);

  /// Glow — moonlit teal, primary accent (bioluminescence).
  static const Color glow = Color(0xFF4DD4C8);

  /// Aurora — amethyst violet, secondary accent.
  static const Color aurora = Color(0xFF8B78F5);

  /// Starlight — pale sky blue, tertiary / emphasis.
  static const Color starlight = Color(0xFFB0CCEF);

  /// Moonbeam — near-white primary text.
  static const Color moonbeam = Color(0xFFE4EAF5);

  /// Fog — muted secondary text.
  static const Color fog = Color(0xFF60758F);

  /// Mist — tertiary text / hint.
  static const Color mist = Color(0xFF445068);

  /// Haze — faint / disabled text.
  static const Color haze = Color(0xFF37425A);

  // Semantic
  static const Color seaGreen = Color(0xFF38C87E);
  static const Color amber = Color(0xFFFFBD5A);
  static const Color crimson = Color(0xFFFF5A7A);

  // ─── Aliases (backward-compat for existing widgets) ───────────────────────
  static const Color primaryColor = glow;
  static const Color secondaryColor = aurora;
  static const Color accentColor = starlight;
  static const Color backgroundColor = midnight;
  static const Color surfaceColor = deepSea;
  static const Color cardColor = tidePool;
  static const Color successColor = seaGreen;
  static const Color warningColor = amber;
  static const Color errorColor = crimson;

  // ─── Radius ───────────────────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 9999;

  // ─── Typography helpers (map to bodypress DM Sans styling) ────────────────
  static TextStyle geist({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
    double? height,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
    height: height,
  );

  static TextStyle geistMono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing ?? -0.2,
    color: color,
  );

  // ─── Typography ───────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: moonbeam,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        color: moonbeam,
      ),
      displaySmall: GoogleFonts.dmSans(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: moonbeam,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: moonbeam,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: moonbeam,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: moonbeam,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: moonbeam,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: moonbeam,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: moonbeam,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: moonbeam,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: fog,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: fog,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: moonbeam,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: fog,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: fog,
      ),
    );
  }

  // ─── Dark Theme — Midnight Ocean ──────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: glow,
        onPrimary: void_,
        primaryContainer: Color(0xFF0E3130),
        onPrimaryContainer: glow,
        secondary: aurora,
        onSecondary: void_,
        secondaryContainer: Color(0xFF1E1840),
        onSecondaryContainer: aurora,
        tertiary: starlight,
        onTertiary: void_,
        surface: deepSea,
        onSurface: moonbeam,
        surfaceContainerHighest: current,
        surfaceContainerLow: tidePool,
        error: crimson,
        onError: moonbeam,
        outline: shimmer,
        outlineVariant: Color(0xFF182030),
      ),
      scaffoldBackgroundColor: midnight,
      textTheme: _buildTextTheme(),
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        foregroundColor: moonbeam,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: moonbeam,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: fog, size: 22),
        actionsIconTheme: const IconThemeData(color: fog, size: 22),
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: shimmer, width: 0.5),
        ),
        color: tidePool,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      // ── Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: glow,
          foregroundColor: void_,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: glow,
          side: const BorderSide(color: glow, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: glow,
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tidePool,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: shimmer, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: shimmer, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glow, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: fog, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: fog, fontSize: 14),
        prefixIconColor: fog,
        suffixIconColor: fog,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      // ── Dividers ──
      dividerTheme: const DividerThemeData(
        color: shimmer,
        thickness: 0.5,
        space: 0,
      ),
      // ── Icons ──
      iconTheme: const IconThemeData(color: fog, size: 22),
      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: tidePool,
        side: const BorderSide(color: shimmer, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: moonbeam),
        selectedColor: glow.withValues(alpha: 0.15),
      ),
      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: current,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: moonbeam,
        ),
      ),
      // ── Bottom sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: current,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      // ── Slider ──
      sliderTheme: const SliderThemeData(
        activeTrackColor: glow,
        thumbColor: glow,
        inactiveTrackColor: shimmer,
        overlayColor: Color(0x224DD4C8),
      ),
      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? glow : fog,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? glow.withValues(alpha: 0.35)
              : shimmer,
        ),
      ),
      // ── Progress indicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: glow,
        linearTrackColor: shimmer,
      ),
      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: current,
        contentTextStyle: GoogleFonts.dmSans(color: moonbeam, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Light Theme (minimal, kept for compatibility) ─────────────────────────
  static ThemeData get lightTheme {
    final base = _buildTextTheme().apply(
      bodyColor: const Color(0xFF1A2340),
      displayColor: const Color(0xFF1A2340),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0F7B70),
        secondary: const Color(0xFF5B4AD0),
        surface: Colors.white,
        error: errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F4FB),
      textTheme: base,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A2340),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A2340),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDDE4F0), width: 0.5),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
