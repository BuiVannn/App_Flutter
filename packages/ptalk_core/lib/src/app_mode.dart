/// Chế độ hoạt động — mỗi chế độ có endpoint, theme, nội dung riêng.
/// Port từ AppMode.kt (Android).
enum AppMode {
  kidMentor(
    httpBasePath: 'v2',
    wsPath: 'v2/ws',
    brandTitle: 'KID MENTOR',
    greetingText: 'Xin chào!',
    subGreetingText: 'Hôm nay, tớ có thể giúp gì cho cậu?',
    statusIdleText: 'Giữ nút để nói chuyện',
  ),
  elderCare(
    httpBasePath: 'eldercare',
    wsPath: 'eldercare/ws',
    brandTitle: 'ELDER CARE',
    greetingText: 'Xin chào!',
    subGreetingText: 'Hôm nay, tôi có thể giúp gì cho bác?',
    statusIdleText: 'Giữ nút để nói chuyện',
  );

  const AppMode({
    required this.httpBasePath,
    required this.wsPath,
    required this.brandTitle,
    required this.greetingText,
    required this.subGreetingText,
    required this.statusIdleText,
  });

  final String httpBasePath;
  final String wsPath;
  final String brandTitle;
  final String greetingText;
  final String subGreetingText;
  final String statusIdleText;

  String httpBaseUrl() => '${ServerConfig.serverHost}/$httpBasePath/';
  String wsUrl() => 'ws://${ServerConfig.serverHostRaw}/$wsPath';
}

/// Cấu hình server — port từ ServerConfig.kt.
class ServerConfig {
  static const serverHostRaw = '171.226.10.121:8000';
  static const serverHost = 'http://$serverHostRaw';

  /// Chế độ đang chọn (đặt lúc runtime ở màn ModeSelect).
  static AppMode activeMode = AppMode.kidMentor;

  static String get httpBaseUrl => activeMode.httpBaseUrl();
  static String get wsUrl => activeMode.wsUrl();
}
