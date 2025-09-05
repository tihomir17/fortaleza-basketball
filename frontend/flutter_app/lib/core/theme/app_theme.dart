// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

class AppTheme {
  // --- BRAND COLORS ---
  static const Color primaryColor = Color(0xFF0A192F); // Deep Navy Blue
  static const Color accentColor = Color(0xFFF9A825); // Vibrant Gold/Orange
  static const Color lightBackgroundColor = Color(0xFFF4F6F8);
  static const Color lightSurfaceColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return _buildTheme(
      base: ThemeData.light(useMaterial3: true),
      primary: primaryColor,
      accent: accentColor,
      background: Colors.grey.shade100,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return _buildTheme(
      base: ThemeData.dark(useMaterial3: true),
      primary: accentColor,
      accent: primaryColor,
      background: const Color(0xFF0A192F), // Use primary as dark background
      surface: const Color(0xFF172A46), // A slightly lighter navy for surfaces
      onPrimary: Colors.black87,
      onSurface: Colors.white,
    );
  }

  // --- CORE THEME BUILDER ---
  static ThemeData _buildTheme({
    required ThemeData base,
    required Color primary,
    required Color accent,
    required Color background,
    required Color surface,
    required Color onPrimary,
    required Color onSurface,
  }) {
    logger.d('AppTheme: Building theme with primary: $primary, accent: $accent');
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: onPrimary,
        onSurface: onSurface,
      ),
      textTheme: _buildTextTheme(base.textTheme, onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Anton', // Bold heading font
          fontSize: 24,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: base.dividerColor, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background.withAlpha(200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),
    );
  }

  // --- TYPOGRAPHY ---
  static TextTheme _buildTextTheme(TextTheme base, Color onSurfaceColor) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: 'Anton',
            color: onSurfaceColor,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: 'Montserrat',
            fontSize: 16,
          ),
          bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Montserrat'),
          bodySmall: base.bodySmall?.copyWith(fontFamily: 'Montserrat'),
          labelLarge: base.labelLarge?.copyWith(fontFamily: 'Montserrat'),
          labelMedium: base.labelMedium?.copyWith(fontFamily: 'Montserrat'),
          labelSmall: base.labelSmall?.copyWith(fontFamily: 'Montserrat'),
        )
        .apply(bodyColor: onSurfaceColor, displayColor: onSurfaceColor);
  }
}
