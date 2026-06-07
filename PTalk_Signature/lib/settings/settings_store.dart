import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu cài đặt không nhạy cảm (theme, số khẩn cấp, quota) — port ThemePrefs.kt
/// + AppSettings.kt + QuotaManager.kt.
class SettingsStore {
  SettingsStore(this._p);
  final SharedPreferences _p;

  static Future<SettingsStore> create() async =>
      SettingsStore(await SharedPreferences.getInstance());

  // ── Theme ──────────────────────────────────────────────
  static const _kTheme = 'theme_mode'; // 'light' | 'dark' | 'system'
  ThemeMode get themeMode => switch (_p.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
  Future<void> setThemeMode(ThemeMode m) => _p.setString(
      _kTheme,
      switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });

  // ── Số gọi khẩn cấp (Elder) ────────────────────────────
  static const _kEmergency = 'emergency_number';
  String get emergencyNumber => _p.getString(_kEmergency) ?? '113';
  Future<void> setEmergencyNumber(String v) =>
      _p.setString(_kEmergency, v.trim());

  // ── Quota khách (20/ngày) ──────────────────────────────
  static const _kCount = 'guest_request_count';
  static const _kReset = 'last_count_reset_date';
  static const guestDailyLimit = 20;

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _rolloverIfNeeded() {
    if (_p.getString(_kReset) != _today()) {
      _p.setInt(_kCount, 0);
      _p.setString(_kReset, _today());
    }
  }

  int get guestUsed {
    _rolloverIfNeeded();
    return _p.getInt(_kCount) ?? 0;
  }

  bool get isGuestQuotaExhausted => guestUsed >= guestDailyLimit;

  /// Tăng 1 lượt; trả về false nếu đã hết quota.
  Future<bool> incrementGuestRequest() async {
    _rolloverIfNeeded();
    final used = _p.getInt(_kCount) ?? 0;
    if (used >= guestDailyLimit) return false;
    await _p.setInt(_kCount, used + 1);
    return true;
  }
}
