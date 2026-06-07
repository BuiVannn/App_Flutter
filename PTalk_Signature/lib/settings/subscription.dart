import 'dart:convert';

/// Gói cước — port SubscriptionActivity.kt.
class SubPlan {
  final String tier; // basic | pro | ultra
  final String name;
  final String quota;
  final String price;
  final String? badge;
  const SubPlan(this.tier, this.name, this.quota, this.price, this.badge);

  static const all = [
    SubPlan('basic', 'Cơ Bản', '20 câu hỏi mỗi ngày', 'Miễn phí', null),
    SubPlan('pro', 'Pro', '500 câu hỏi mỗi ngày', '800.000đ/tháng',
        '★ Đáng giá nhất'),
    SubPlan('ultra', 'Ultra', 'Không giới hạn câu hỏi', '1.500.000đ/tháng',
        null),
  ];

  static int rank(String tier) => switch (tier) {
        'ultra' => 3,
        'pro' => 2,
        'admin' => 4,
        _ => 1, // basic
      };
}

/// Suy ra tier từ JWT (claim subscription_tier / is_superuser).
String resolveTier(String? jwt) {
  if (jwt == null) return 'basic';
  final parts = jwt.split('.');
  if (parts.length < 2) return 'basic';
  try {
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final claims =
        jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
    if (claims['is_superuser'] == true) return 'admin';
    final t = claims['subscription_tier'];
    if (t is String && ['basic', 'pro', 'ultra'].contains(t)) return t;
  } catch (_) {}
  return 'basic';
}
