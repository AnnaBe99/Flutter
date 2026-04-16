import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.light));

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') {
      emit(const ThemeState(themeMode: ThemeMode.dark));
    } else {
      emit(const ThemeState(themeMode: ThemeMode.light));
    }
  }

  Future<void> setLightTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, 'light');
    emit(const ThemeState(themeMode: ThemeMode.light));
  }

  Future<void> setDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, 'dark');
    emit(const ThemeState(themeMode: ThemeMode.dark));
  }

  Future<void> toggleTheme(bool isDark) async {
    if (isDark) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
}