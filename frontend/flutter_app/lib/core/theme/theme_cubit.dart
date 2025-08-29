// lib/core/theme/theme_cubit.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/main.dart'; // Import for global logger

// The state is simple: just the current ThemeMode.
// We don't need a separate state file for this.

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'appTheme';

  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme(); // Load the saved theme when the cubit is created
    logger.i('ThemeCubit initialized. Attempting to load saved theme.');
  }

  // Load the saved theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      if (themeName == 'light') {
        emit(ThemeMode.light);
        logger.d('ThemeCubit: Loaded light theme.');
      } else if (themeName == 'dark') {
        emit(ThemeMode.dark);
        logger.d('ThemeCubit: Loaded dark theme.');
      } else {
        emit(ThemeMode.system);
        logger.d('ThemeCubit: Loaded system theme.');
      }
    }
    else {
      logger.d('ThemeCubit: No theme preference found, defaulting to system.');
    }
  }

  // Change the theme and save the new preference
  Future<void> changeTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeName = 'system';
    if (themeMode == ThemeMode.light) {
      themeName = 'light';
    } else if (themeMode == ThemeMode.dark) {
      themeName = 'dark';
    }

    await prefs.setString(_themeKey, themeName);
    emit(themeMode);
    logger.i('ThemeCubit: Changed theme to $themeMode and saved preference: $themeName.');
  }

  // A helper to toggle to the next theme in a cycle
  void toggleTheme() {
    // The cycle is System -> Light -> Dark -> System ...
    logger.d('ThemeCubit: Toggling theme from $state.');
    if (state == ThemeMode.system) {
      changeTheme(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      changeTheme(ThemeMode.dark);
    } else {
      changeTheme(ThemeMode.system);
    }
    logger.d('ThemeCubit: Theme toggled to $state.');
  }
}
