import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  group('DashboardClient', () {
    test('gắn Authorization Bearer từ token cung cấp', () async {
      String? seenAuth;
      final mock = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final client = DashboardClient(
        baseUrl: 'https://x.test',
        httpClient: mock,
        getAccessToken: () async => 'TKN',
        refreshToken: () async => null,
      );

      final res = await client.getJson('/api/v1/profile');

      expect(seenAuth, 'Bearer TKN');
      expect(res['ok'], true);
    });

    test('khi 401 thì refresh rồi thử lại 1 lần', () async {
      var calls = 0;
      var refreshed = false;
      final mock = MockClient((req) async {
        calls++;
        final tkn = req.headers['Authorization'];
        if (tkn == 'Bearer OLD') return http.Response('no', 401);
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      var current = 'OLD';
      final client = DashboardClient(
        baseUrl: 'https://x.test',
        httpClient: mock,
        getAccessToken: () async => current,
        refreshToken: () async {
          refreshed = true;
          current = 'NEW';
          return 'NEW';
        },
      );

      final res = await client.getJson('/api/v1/profile');

      expect(refreshed, true);
      expect(calls, 2);
      expect(res['ok'], true);
    });

    test('401 mà refresh thất bại thì ném ApiUnauthorized', () async {
      final mock = MockClient((_) async => http.Response('no', 401));
      final client = DashboardClient(
        baseUrl: 'https://x.test',
        httpClient: mock,
        getAccessToken: () async => 'OLD',
        refreshToken: () async => null,
      );

      expect(() => client.getJson('/api/v1/profile'),
          throwsA(isA<ApiUnauthorized>()));
    });
  });
}
