import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_storage.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = AppStorage.instance.savedTheme;
    return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await AppStorage.instance.saveTheme(
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void toggle() => setTheme(
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
