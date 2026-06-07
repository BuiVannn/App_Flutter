import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_store.dart';

/// SettingsStore async (khởi tạo SharedPreferences 1 lần).
final settingsStoreProvider = FutureProvider<SettingsStore>((ref) async {
  return SettingsStore.create();
});

/// Theme mode hiện tại — điều khiển MaterialApp.themeMode.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._ref) : super(ThemeMode.system) {
    _load();
  }
  final Ref _ref;

  Future<void> _load() async {
    final store = await _ref.read(settingsStoreProvider.future);
    state = store.themeMode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final store = await _ref.read(settingsStoreProvider.future);
    await store.setThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
        (ref) => ThemeModeController(ref));
