import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'user_theme_mode';

  ThemeCubit() : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isClosed) return;
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'light') {
        emit(ThemeMode.light);
      } else if (savedTheme == 'dark') {
        emit(ThemeMode.dark);
      } else if (savedTheme == 'system') {
        emit(ThemeMode.system);
      } else {
        emit(ThemeMode.dark);
      }
    } catch (_) {
      if (!isClosed) emit(ThemeMode.dark);
    }
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(nextMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        nextMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        mode == ThemeMode.light
            ? 'light'
            : (mode == ThemeMode.system ? 'system' : 'dark'),
      );
    } catch (_) {}
  }

  bool get isDark => state == ThemeMode.dark;

  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
