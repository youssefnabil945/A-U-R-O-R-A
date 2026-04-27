import 'package:flutter/material.dart';
import 'package:aurora/theme/themeprovider.dart';

/// Enum defining the available app themes
enum AppThemeType {
  lightDefault,
  lightOcean,
  lightForest,
  darkDefault,
  darkMidnight,
  darkSunset,
}

/// Extension to get display names for themes
extension AppThemeTypeExtension on AppThemeType {
  String get name {
    switch (this) {
      case AppThemeType.lightDefault:
        return 'Light Default';
      case AppThemeType.lightOcean:
        return 'Light Ocean';
      case AppThemeType.lightForest:
        return 'Light Forest';
      case AppThemeType.darkDefault:
        return 'Dark Default';
      case AppThemeType.darkMidnight:
        return 'Dark Midnight';
      case AppThemeType.darkSunset:
        return 'Dark Sunset';
    }
  }

  bool get isDark {
    switch (this) {
      case AppThemeType.lightDefault:
      case AppThemeType.lightOcean:
      case AppThemeType.lightForest:
        return false;
      case AppThemeType.darkDefault:
      case AppThemeType.darkMidnight:
      case AppThemeType.darkSunset:
        return true;
    }
  }
}

/// Extension to convert AppThemeId to AppThemeType
extension AppThemeIdToTypeExtension on AppThemeId {
  AppThemeType toAppThemeType() {
    switch (this) {
      case AppThemeId.lightDefault:
        return AppThemeType.lightDefault;
      case AppThemeId.lightOcean:
        return AppThemeType.lightOcean;
      case AppThemeId.lightForest:
        return AppThemeType.lightForest;
      case AppThemeId.darkDefault:
        return AppThemeType.darkDefault;
      case AppThemeId.darkMidnight:
        return AppThemeType.darkMidnight;
      case AppThemeId.darkSunset:
        return AppThemeType.darkSunset;
    }
  }
}

/// Helper class to generate ThemeData based on the selected theme type
class AuroraThemeData {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.lightDefault:
        return _lightDefault();
      case AppThemeType.lightOcean:
        return _lightOcean();
      case AppThemeType.lightForest:
        return _lightForest();
      case AppThemeType.darkDefault:
        return _darkDefault();
      case AppThemeType.darkMidnight:
        return _darkMidnight();
      case AppThemeType.darkSunset:
        return _darkSunset();
    }
  }

  // --- LIGHT THEMES ---

  static ThemeData _lightDefault() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6200EE),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6200EE),
        secondary: Color(0xFF03DAC6),
        surface: Colors.white,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6200EE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6200EE),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _lightOcean() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0077B6),
      scaffoldBackgroundColor: const Color(0xFFF0F8FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0077B6),
        secondary: Color(0xFF90E0EF),
        surface: Colors.white,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF023E8A),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0077B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF0077B6),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF90E0EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF90E0EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _lightForest() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF2D6A4F),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2D6A4F),
        secondary: Color(0xFF95D5B2),
        surface: Colors.white,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF1B4332),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF95D5B2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF95D5B2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  // --- DARK THEMES ---

  static ThemeData _darkDefault() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFBB86FC),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFBB86FC),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFBB86FC),
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFBB86FC), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _darkMidnight() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF3A86FF),
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3A86FF),
        secondary: Color(0xFF8338EC),
        surface: Color(0xFF15192B),
        error: Color(0xFFFB5607),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F19),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF15192B),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF3A86FF),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F253D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A86FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A86FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A86FF), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData _darkSunset() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFFF7E67),
      scaffoldBackgroundColor: const Color(0xFF1A0B0B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF7E67),
        secondary: Color(0xFFFFD166),
        surface: Color(0xFF2D1B1B),
        error: Color(0xFFEF476F),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A0B0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D1B1B),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFF7E67),
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3D2525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF7E67)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF7E67)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF7E67), width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }
}
