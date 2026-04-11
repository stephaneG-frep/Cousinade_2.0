import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController()..load(),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.dark);

  static const _themeModeKey = 'theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_themeModeKey);

    if (storedValue == 'light') {
      state = ThemeMode.light;
      return;
    }

    state = ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light ? 'light' : 'dark';
    await prefs.setString(_themeModeKey, value);
  }
}
