import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_result.dart';

/// Lưu token an toàn (Keychain iOS / Keystore Android) — thay
/// EncryptedSharedPreferences của bản Android (TokenManager.kt).
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _s;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUsername = 'username';
  static const _kEmail = 'email';
  static const _kUserType = 'user_type';
  static const _kExpiresAt = 'expires_at';

  Future<void> saveFromAuthResult(AuthResult r) async {
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + r.expiresIn * 1000;
    await _s.write(key: _kAccess, value: r.accessToken);
    await _s.write(key: _kRefresh, value: r.refreshToken);
    await _s.write(key: _kExpiresAt, value: '$expiresAt');
    if (r.name.isNotEmpty) await _s.write(key: _kUsername, value: r.name);
    if (r.userType.isNotEmpty) {
      await _s.write(key: _kUserType, value: r.userType);
    }
    if (r.email.isNotEmpty) await _s.write(key: _kEmail, value: r.email);
  }

  Future<String?> get accessToken => _s.read(key: _kAccess);
  Future<String?> get refreshToken => _s.read(key: _kRefresh);
  Future<String?> get username => _s.read(key: _kUsername);
  Future<String?> get email => _s.read(key: _kEmail);
  Future<String?> get userType => _s.read(key: _kUserType);

  Future<bool> isLoggedIn() async {
    final t = await accessToken;
    return t != null && t.isNotEmpty;
  }

  /// Hết hạn (đệm 60s lệch đồng hồ).
  Future<bool> isTokenExpired() async {
    final raw = await _s.read(key: _kExpiresAt);
    final expiresAt = int.tryParse(raw ?? '') ?? 0;
    return DateTime.now().millisecondsSinceEpoch > (expiresAt - 60000);
  }

  Future<void> clear() => _s.deleteAll();
}
