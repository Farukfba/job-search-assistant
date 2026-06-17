import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
/// Centralized design tokens for the Job Search Assistant.
///
/// Palette:
///   ink    #1C1B1A — primary text, near-black with a warm undertone
///   paper  #FAF8F5 — background, warm off-white
///   pine   #2D5C4D — primary accent (confidence, growth)
///   sand   #E8E2D6 — secondary surface (cards, dividers)
///   ember  #C4622D — single warm accent (match scores, urgent CTAs)
///   stone  #6B6862 — secondary/muted text
class AppColors {
  static const ink = Color(0xFF1C1B1A);
  static const paper = Color(0xFFFAF8F5);
  static const pine = Color(0xFF2D5C4D);
  static const pineLight = Color(0xFFE3ECE8);
  static const sand = Color(0xFFE8E2D6);
  static const ember = Color(0xFFC4622D);
  static const emberLight = Color(0xFFF7E8DD);
  static const stone = Color(0xFF6B6862);
  static const success = Color(0xFF2D5C4D);
  static const warning = Color(0xFFC4622D);
  static const danger = Color(0xFFB3401F);
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    final textTheme = base.textTheme.copyWith(
      // Display: Fraunces — used sparingly, for screen titles and the
      // match-score number. Carries the app's personality.
      displayLarge: TextStyle(
        fontFamily: GoogleFonts.fraunces().fontFamily,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.1,
      ),
      headlineMedium: TextStyle(
        fontFamily: GoogleFonts.fraunces().fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontFamily: GoogleFonts.fraunces().fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      // Body/UI: Inter — the workhorse for everything else.
      titleMedium: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.stone,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: GoogleFonts.inter().fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pine,
        onPrimary: AppColors.paper,
        secondary: AppColors.ember,
        onSecondary: AppColors.paper,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.fraunces().fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.sand, width: 1),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.pineLight,
        labelStyle: TextStyle(
          fontFamily: GoogleFonts.inter().fontFamily,
          fontSize: 13,
          color: AppColors.pine,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pine,
          foregroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.sand, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle:  TextStyle(fontFamily: GoogleFonts.inter().fontFamily, color: AppColors.stone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pine, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.pineLight,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
           TextStyle(fontFamily: GoogleFonts.inter().fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.pine);
          }
          return const IconThemeData(color: AppColors.stone);
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.sand, thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.ink),
    );
  }
}