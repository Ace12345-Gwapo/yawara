// ============================================================
// lib/services/theme_service.dart
// NEW: Global theme management (Light / Dark mode).
//
// Usage:
//   ThemeService.themeMode.value = ThemeMode.dark;
//   await ThemeService.save();
//
// In main.dart wrap app with ValueListenableBuilder on
// ThemeService.themeMode.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'app_theme_mode';

  /// Global notifier — rebuild the app whenever this changes.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Load persisted preference on startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }

  /// Toggle and persist.
  static Future<void> toggle() async {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      themeMode.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  // ── Theme data ─────────────────────────────────────────────

  static const _green = Color(0xFF1B5E20);
  static const _greenLight = Color(0xFF2E7D32);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorSchemeSeed: _green,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        cardColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
        ),
        dividerColor: const Color(0xFFE5E7EB),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF111827)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorSchemeSeed: _greenLight,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2E1A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        cardColor: const Color(0xFF1E1E1E),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          fillColor: const Color(0xFF2A2A2A),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _greenLight,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
        ),
        dividerColor: const Color(0xFF333333),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
          bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
        ),
      );
}