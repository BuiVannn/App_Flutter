import '../net/dashboard_client.dart';
import 'models.dart';

/// Đọc hồ sơ phụ huynh / bé / lượt dùng từ Dashboard v1.
class ProfileRepository {
  ProfileRepository(this._client);
  final DashboardClient _client;

  Future<ParentProfile> getParent() async {
    final json = await _client.getJson('/api/v1/profile');
    final p = (json['profile'] as Map?)?.cast<String, dynamic>() ?? {};
    return ParentProfile.fromJson(p);
  }

  Future<UsageToday> getUsageToday() async {
    final json = await _client.getJson('/api/v1/profile');
    final p = (json['profile'] as Map?)?.cast<String, dynamic>() ?? {};
    return UsageToday.fromJson(p);
  }

  Future<List<ChildProfile>> getChildren() async {
    final json = await _client.getJson('/api/v1/children');
    final list = (json['children'] as List?) ?? const [];
    return list
        .map((e) => ChildProfile.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<ChildProfile> getChild(String id) async {
    final json = await _client.getJson('/api/v1/children/$id');
    final c = (json['child'] as Map?)?.cast<String, dynamic>() ?? {};
    return ChildProfile.fromJson(c);
  }
}
