import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors ---
  static const Color primaryGreen = Color(0xFF105C38); // Deep Emerald Green
  static const Color secondaryGreen = Color(0xFF1B8052); // Lighter Green for gradients
  static const Color accentGold = Color(0xFFD4AF37); // Luxury Gold
  static const Color backgroundLight = Color(0xFFF4F9F6); // Very subtle mint white
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color errorRed = Color(0xFFD32F2F);

  // --- Text Styles ---
  static final TextTheme _textTheme = GoogleFonts.montserratTextTheme();

  // --- Theme Data ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGold,
        surface: surfaceWhite,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      
      // Typography
      textTheme: _textTheme.copyWith(
        displayLarge: _textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryGreen),
        headlineMedium: _textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: primaryGreen),
        titleLarge: _textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: _textTheme.bodyLarge?.copyWith(color: textDark),
        bodyMedium: _textTheme.bodyMedium?.copyWith(color: textDark),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primaryGreen),
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: const TextStyle(color: textGrey),
        floatingLabelStyle: const TextStyle(color: primaryGreen),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGreen.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
}
