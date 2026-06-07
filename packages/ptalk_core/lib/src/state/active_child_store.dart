import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models.dart';

/// Lưu "bé đang dùng app" trên thiết bị (đính vào phiên voice).
class ActiveChildStore {
  ActiveChildStore({FlutterSecureStorage? storage})
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );
  final FlutterSecureStorage _s;
  static const _k = 'active_child';

  Future<void> save(ActiveChild c) => _s.write(
        key: _k,
        value: jsonEncode({
          'childId': c.childId,
          'username': c.username,
          'fullName': c.fullName,
        }),
      );

  Future<ActiveChild?> read() async {
    final raw = await _s.read(key: _k);
    if (raw == null || raw.isEmpty) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return ActiveChild(
      childId: j['childId'] as String,
      username: j['username'] as String,
      fullName: j['fullName'] as String,
    );
  }

  Future<void> clear() => _s.delete(key: _k);
}
