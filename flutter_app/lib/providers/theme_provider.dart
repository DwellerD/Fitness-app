import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppTheme { light, dark, crimsonNight }

class ThemeProvider extends ChangeNotifier {
  static const _storageKey = 'selectedTheme';
  final _secureStorage = const FlutterSecureStorage();
  
  AppTheme _currentTheme = AppTheme.light;
  
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => _getThemeData(_currentTheme);

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final saved = await _secureStorage.read(key: _storageKey);
      if (saved != null) {
        _currentTheme = AppTheme.values.firstWhere(
          (t) => t.name == saved,
          orElse: () => AppTheme.light,
        );
        notifyListeners();
      }
    } catch (e) {
      // If error, keep default light theme
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _secureStorage.write(key: _storageKey, value: theme.name);
    notifyListeners();
  }

  ThemeData _getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return _lightTheme;
      case AppTheme.dark:
        return _darkTheme;
      case AppTheme.crimsonNight:
        return _crimsonNightTheme;
    }
  }

  static final _lightTheme = ThemeData(
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
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    ),
  );

  static final _darkTheme = ThemeData(
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
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFBB86FC),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
    ),
  );

  static final _crimsonNightTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFDC143C),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFDC143C),
      secondary: Color(0xFFFF6B6B),
      surface: Color(0xFF1A0A0A),
      error: Color(0xFFFF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFFFE4E4),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A0A0A),
      foregroundColor: Color(0xFFFFE4E4),
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A0A0A),
      selectedItemColor: Color(0xFFDC143C),
      unselectedItemColor: Color(0xFF666666),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A0A0A),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDC143C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: const Color(0xFF2A1A1A),
      labelStyle: const TextStyle(color: Color(0xFFFFE4E4)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFFE4E4)),
      bodyMedium: TextStyle(color: Color(0xFFFFE4E4)),
      bodySmall: TextStyle(color: Color(0xFFCCAAAA)),
      titleLarge: TextStyle(color: Color(0xFFFFE4E4)),
      titleMedium: TextStyle(color: Color(0xFFFFE4E4)),
      titleSmall: TextStyle(color: Color(0xFFFFE4E4)),
    ),
  );
}
