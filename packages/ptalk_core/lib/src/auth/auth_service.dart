import 'package:flutter_appauth/flutter_appauth.dart';
import 'auth_config.dart';
import 'auth_result.dart';

/// Bọc luồng Authentik OIDC bằng flutter_appauth.
/// Port từ AuthentikAuthManager.kt (cùng backend).
class AuthService {
  AuthService({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  static const _serviceConfig = AuthorizationServiceConfiguration(
    authorizationEndpoint: AuthConfig.authEndpoint,
    tokenEndpoint: AuthConfig.tokenEndpoint,
    endSessionEndpoint: AuthConfig.endSessionEndpoint,
  );

  /// Mở trình duyệt SSO, đổi code lấy token. Ném [AuthException] nếu lỗi.
  Future<AuthResult> login() async {
    try {
      final res = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUri,
          clientSecret: AuthConfig.clientSecret,
          serviceConfiguration: _serviceConfig,
          scopes: AuthConfig.scopes,
        ),
      );
      return _toResult(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
        idToken: res.idToken,
        expiration: res.accessTokenExpirationDateTime,
      );
    } on Exception catch (e) {
      throw AuthException('Đăng nhập thất bại: $e');
    }
  }

  /// Làm mới token bằng refresh_token.
  Future<AuthResult> refresh(String refreshToken) async {
    try {
      final res = await _appAuth.token(
        TokenRequest(
          AuthConfig.clientId,
          AuthConfig.redirectUri,
          clientSecret: AuthConfig.clientSecret,
          refreshToken: refreshToken,
          grantType: 'refresh_token',
          serviceConfiguration: _serviceConfig,
          scopes: AuthConfig.scopes,
        ),
      );
      return _toResult(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
        idToken: res.idToken,
        expiration: res.accessTokenExpirationDateTime,
      );
    } on Exception catch (e) {
      throw AuthException('Làm mới phiên thất bại: $e');
    }
  }

  /// Đăng xuất khỏi Authentik (xoá phiên SSO trên trình duyệt).
  Future<void> logout(String idToken) async {
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: AuthConfig.redirectUri,
          serviceConfiguration: _serviceConfig,
        ),
      );
    } on Exception {
      // Bỏ qua lỗi end-session; token local vẫn bị xoá ở tầng trên.
    }
  }

  AuthResult _toResult({
    required String? accessToken,
    required String? refreshToken,
    required String? idToken,
    required DateTime? expiration,
  }) {
    final expiresIn = expiration != null
        ? expiration.difference(DateTime.now()).inSeconds
        : 3600;
    return AuthResult.fromTokens(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
      idToken: idToken ?? '',
      expiresIn: expiresIn > 0 ? expiresIn : 3600,
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
