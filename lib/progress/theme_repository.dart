import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<ThemeMode> load() async =>
      (await _preferences.getBool('light_theme') ?? false)
      ? ThemeMode.light
      : ThemeMode.dark;

  Future<void> save(ThemeMode mode) =>
      _preferences.setBool('light_theme', mode == ThemeMode.light);
}
