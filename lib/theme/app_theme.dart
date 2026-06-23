import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const surfaceDark = Color(0xFF1A1A1A); // terminal block

  // Text
  static const ink = Color(0xFF0F0F0F);
  static const muted = Color(0xFF8A8A8A);
  static const placeholder = Color(0xFFBBBBBB);

  // Primary green
  static const green = Color(0xFF2B9E5E);
  static const greenLight = Color(0xFFE8F7EF);
  static const greenDark = Color(0xFF1F7A47);

  // Score colors
  static const scoreHigh = Color(0xFF2B9E5E);   // 75+
  static const scoreMid = Color(0xFF3B82F6);    // 50–74 (blue)
  static const scoreLow = Color(0xFFF59E0B);    // <50 (amber/orange)

  // Status colors
  static const interview = Color(0xFFF59E0B);   // amber
  static const applied = Color(0xFF3B82F6);     // blue
  static const offer = Color(0xFF2B9E5E);       // green
  static const rejected = Color(0xFFEF4444);    // red

  // Utility
  static const divider = Color(0xFFE8E8E8);
  static const border = Color(0xFFE0E0E0);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);

  // Terminal
  static const terminalBg = Color(0xFF1C1C1C);
  static const terminalGreen = Color(0xFF4ADE80);
  static const terminalText = Color(0xFF9CA3AF);

  // Legacy aliases for any remaining code that references old colors
  static const paper = white;
  static const pine = green;
  static const pineLight = greenLight;
  static const ember = Color(0xFFF59E0B);
  static const emberLight = Color(0xFFFEF3C7);
  static const stone = muted;
  static const line = divider;
}

class AppTheme {
  static ThemeData get theme {
    final sans = GoogleFonts.inter().fontFamily!;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        onPrimary: AppColors.white,
        secondary: AppColors.scoreMid,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      textTheme: TextTheme(
        // Heavy display — onboarding headlines
        displayLarge: TextStyle(fontFamily: sans, fontSize: 36,
            fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1),
        // Screen titles — "Tracker", "Profile"
        headlineLarge: TextStyle(fontFamily: sans, fontSize: 28,
            fontWeight: FontWeight.w800, color: AppColors.ink),
        headlineMedium: TextStyle(fontFamily: sans, fontSize: 22,
            fontWeight: FontWeight.w700, color: AppColors.ink),
        headlineSmall: TextStyle(fontFamily: sans, fontSize: 18,
            fontWeight: FontWeight.w700, color: AppColors.ink),
        // Card titles
        titleLarge: TextStyle(fontFamily: sans, fontSize: 16,
            fontWeight: FontWeight.w700, color: AppColors.ink),
        titleMedium: TextStyle(fontFamily: sans, fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.ink),
        titleSmall: TextStyle(fontFamily: sans, fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.ink),
        // Body
        bodyLarge: TextStyle(fontFamily: sans, fontSize: 15,
            fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.6),
        bodyMedium: TextStyle(fontFamily: sans, fontSize: 13,
            fontWeight: FontWeight.w400, color: AppColors.muted, height: 1.5),
        bodySmall: TextStyle(fontFamily: sans, fontSize: 12,
            fontWeight: FontWeight.w400, color: AppColors.muted),
        // Labels — uppercase metadata
        labelLarge: TextStyle(fontFamily: sans, fontSize: 12,
            fontWeight: FontWeight.w600, color: AppColors.ink),
        labelMedium: TextStyle(fontFamily: sans, fontSize: 11,
            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5),
        labelSmall: TextStyle(fontFamily: sans, fontSize: 10,
            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: sans, fontSize: 16,
            fontWeight: FontWeight.w700, color: AppColors.ink),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(fontFamily: sans, fontSize: 15,
            color: AppColors.placeholder, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        labelStyle: TextStyle(fontFamily: sans, fontSize: 11,
            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greenLight,
        labelStyle: TextStyle(fontFamily: sans, fontSize: 13,
            color: AppColors.green, fontWeight: FontWeight.w500),
        side: const BorderSide(color: AppColors.green, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 60,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w500,
            color: active ? AppColors.green : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.green : AppColors.muted,
            size: 22,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}