import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ptalk_core/ptalk_core.dart';

DashboardClient _clientReturning(Map<String, Object?> Function(String path) body) {
  final mock = MockClient((req) async =>
      http.Response(jsonEncode(body(req.url.path)), 200));
  return DashboardClient(
    baseUrl: 'https://x.test',
    httpClient: mock,
    getAccessToken: () async => 'TKN',
    refreshToken: () async => null,
  );
}

void main() {
  test('getParent parse profile', () async {
    final repo = ProfileRepository(_clientReturning((_) => {
          'profile': {
            'fullName': 'Nam', 'phone': '09', 'email': 'a@b.vn',
            'subscriptionTier': 'ultra', 'usageToday': 3, 'quota': null,
          }
        }));
    final p = await repo.getParent();
    expect(p.fullName, 'Nam');
    expect(p.subscriptionTier, 'ultra');
  });

  test('getChildren parse danh sách', () async {
    final repo = ProfileRepository(_clientReturning((_) => {
          'children': [
            {'id': '1', 'username': 'child_1', 'fullName': 'An', 'grade': '4', 'relationship': 'father'},
            {'id': '2', 'username': 'child_2', 'fullName': 'Chi', 'grade': '2', 'relationship': 'father'},
          ]
        }));
    final list = await repo.getChildren();
    expect(list.length, 2);
    expect(list.first.gradeLabel, 'Lớp 4');
  });

  test('getUsageToday parse', () async {
    final repo = ProfileRepository(_clientReturning((_) => {
          'profile': {'usageToday': 12, 'quota': 500, 'resetsAt': '2026-06-08T00:00:00Z'}
        }));
    final u = await repo.getUsageToday();
    expect(u.used, 12);
    expect(u.quota, 500);
  });
}
