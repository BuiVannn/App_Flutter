import 'dart:convert';

/// Kết quả sau khi đổi code → token, kèm claims giải mã từ id_token.
/// Port từ AuthentikAuthManager.AuthResult (Android).
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String idToken;
  final int expiresIn;
  final String userId;
  final String email;
  final String name;
  final List<String> groups;
  final String userType;
  final List<String> assignedProducts;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresIn,
    required this.userId,
    required this.email,
    required this.name,
    required this.groups,
    required this.userType,
    required this.assignedProducts,
  });

  /// Dựng từ token + id_token JWT (giải mã payload để lấy claims).
  factory AuthResult.fromTokens({
    required String accessToken,
    required String refreshToken,
    required String idToken,
    required int expiresIn,
  }) {
    final claims = _parseJwtClaims(idToken);
    List<String> strList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];
    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresIn: expiresIn,
      userId: (claims['sub'] ?? '') as String,
      email: (claims['email'] ?? '') as String,
      name: (claims['name'] ?? claims['preferred_username'] ?? '') as String,
      groups: strList(claims['groups']),
      userType: (claims['user_type'] ?? 'child') as String,
      assignedProducts: strList(claims['assigned_products']),
    );
  }

  static Map<String, dynamic> _parseJwtClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    try {
      return jsonDecode(utf8.decode(base64.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
