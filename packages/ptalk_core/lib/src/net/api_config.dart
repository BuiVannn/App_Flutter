/// Cấu hình endpoint backend Dashboard (API v1 cho mobile).
/// Ghi đè khi build qua --dart-define=DASHBOARD_BASE_URL=...
class ApiConfig {
  static const dashboardBaseUrl = String.fromEnvironment(
    'DASHBOARD_BASE_URL',
    defaultValue: 'https://dashboard.ctslab.net',
  );
}
