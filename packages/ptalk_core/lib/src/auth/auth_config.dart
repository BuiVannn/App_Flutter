/// Cấu hình Authentik OIDC — port từ AuthentikConfig.kt.
///
/// LƯU Ý (giữ nguyên từ bản Android): tạm trỏ về client `kid-mentor` đã đăng ký
/// vì provider/app `ptalk-signature` chưa tồn tại trên Authentik. Khi tạo xong
/// client riêng, đổi 5 hằng số dưới sang ptalk-signature/*.
class AuthConfig {
  static const issuerUrl =
      'https://auth.ctslab.net/application/o/kid-mentor/';
  static const authEndpoint =
      'https://auth.ctslab.net/application/o/authorize/';
  static const tokenEndpoint =
      'https://auth.ctslab.net/application/o/token/';
  static const userinfoEndpoint =
      'https://auth.ctslab.net/application/o/userinfo/';
  static const endSessionEndpoint =
      'https://auth.ctslab.net/application/o/kid-mentor/end-session/';

  static const clientId = 'kid-mentor-client';
  static const clientSecret = 'kid-mentor-secret-key';

  /// Phải khớp redirect đã đăng ký ở provider kid-mentor.
  static const redirectUri = 'app://kidmentor/callback';

  /// Scheme của redirect — phải khai báo ở AndroidManifest + iOS Info.plist.
  static const redirectScheme = 'app';

  static const scopes = <String>[
    'openid',
    'email',
    'profile',
    'roles',
    'user_type',
    'assigned_products',
  ];
}
