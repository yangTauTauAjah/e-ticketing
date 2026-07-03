import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    state = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _key, value: state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final notifier = ThemeNotifier();
  notifier.load();
  return notifier;
});
