# Đồng bộ tài khoản + Màn hồ sơ (PTalk Signature Flutter) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đấu app Flutter vào DB chung (`ptalk_auth`) qua Dashboard v1 API và thêm 4 màn hồ sơ chỉ-xem, để 1 tài khoản đồng bộ giữa các app — tránh lỗi siloed của app cũ.

**Architecture:** Thêm tầng network/data dùng chung vào `packages/ptalk_core` (`DashboardClient` + `ProfileRepository` + models + `ActiveChildStore`). Sau SSO login gọi `GET /api/v1/profile` để kích JIT provisioning (backend tự upsert user theo `sub`). UI ở `PTalk_Signature` đọc qua Riverpod. "Bé đang dùng" lưu local và đặt làm `device_id` trong handshake WS CloudPTalk để AI cá nhân hoá đúng bé.

**Tech Stack:** Flutter, Riverpod, `http`, `flutter_secure_storage`, go_router; backend Next.js 16 (raw SQL `pg`).

**Spec:** `docs/superpowers/specs/2026-06-07-flutter-account-profile-sync-design.md`

**Quy ước:** mọi đường dẫn tương đối tính từ `App_Flutter/` trừ khi ghi rõ. Lệnh Flutter chạy trong package/app tương ứng. Backend chạy trong `Dashboard/dashboard/` (repo riêng).

---

## File Structure

**Tạo mới (`packages/ptalk_core/lib/src/`):**
- `net/api_config.dart` — base URL Dashboard (cấu hình được).
- `net/dashboard_client.dart` — HTTP client gắn Bearer + retry 401.
- `data/models.dart` — `ParentProfile`, `ChildProfile`, `UsageToday`, `ActiveChild` + label helpers.
- `data/profile_repository.dart` — `getParent/getUsageToday/getChildren/getChild`.
- `state/active_child_store.dart` — lưu bé active (secure storage).

**Sửa (`packages/ptalk_core/`):**
- `pubspec.yaml` — thêm `http`.
- `lib/ptalk_core.dart` — export các file mới.

**Tạo mới (`PTalk_Signature/lib/`):**
- `account/account_providers.dart` — Riverpod providers.
- `account/account_screen.dart`, `account/parent_screen.dart`, `account/children_screen.dart`, `account/child_detail_screen.dart`.

**Sửa (`PTalk_Signature/lib/`):**
- `router.dart` — 4 route mới.
- `core/providers.dart` — `loginWithSso()` gọi `ensureUser()`; thêm `dashboardClientProvider`.
- `screens/main_voice_screen.dart` — avatar góc phải → `/account`.
- `screens/settings_screen.dart` — mục TÀI KHOẢN đổi thành 1 link sang `/account`.
- `voice/streaming_voice_client.dart` + `voice/voice_controller.dart` — `device_id` = username bé active nếu có.

**Sửa (backend `Dashboard/dashboard/src/`):**
- `lib/api-auth.ts` — thêm issuer `ptalk-signature`.
- `app/api/v1/profile/route.ts` — trả thêm `subscriptionTier` + `usageToday/quota/resetsAt`.

---

## Phase A — Nền tảng đồng bộ (ptalk_core)

### Task A1: Thêm dependency `http`

**Files:** Modify `packages/ptalk_core/pubspec.yaml`

- [ ] **Step 1: Thêm `http` vào dependencies**

Trong `packages/ptalk_core/pubspec.yaml`, dưới `flutter_secure_storage: ^9.2.2` thêm:

```yaml
  http: ^1.2.0
```

- [ ] **Step 2: Lấy packages**

Run: `cd packages/ptalk_core && flutter pub get`
Expected: "Got dependencies!" không lỗi.

- [ ] **Step 3: Commit**

```bash
git add packages/ptalk_core/pubspec.yaml packages/ptalk_core/pubspec.lock
git commit -m "chore(core): add http dependency for Dashboard API client"
```

### Task A2: ApiConfig — base URL Dashboard

**Files:** Create `packages/ptalk_core/lib/src/net/api_config.dart`

- [ ] **Step 1: Tạo file**

```dart
/// Cấu hình endpoint backend Dashboard (API v1 cho mobile).
/// Ghi đè khi build qua --dart-define=DASHBOARD_BASE_URL=...
class ApiConfig {
  static const dashboardBaseUrl = String.fromEnvironment(
    'DASHBOARD_BASE_URL',
    defaultValue: 'https://dashboard.ctslab.net',
  );
}
```

- [ ] **Step 2: Export**

Trong `packages/ptalk_core/lib/ptalk_core.dart` thêm dòng:

```dart
export 'src/net/api_config.dart';
```

- [ ] **Step 3: Phân tích tĩnh**

Run: `cd packages/ptalk_core && dart analyze lib/src/net/api_config.dart`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add packages/ptalk_core/lib/src/net/api_config.dart packages/ptalk_core/lib/ptalk_core.dart
git commit -m "feat(core): add ApiConfig with Dashboard base URL"
```

### Task A3: DashboardClient (Bearer + retry 401)

**Files:**
- Create: `packages/ptalk_core/lib/src/net/dashboard_client.dart`
- Test: `packages/ptalk_core/test/net/dashboard_client_test.dart`

- [ ] **Step 1: Viết test thất bại**

```dart
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
```

- [ ] **Step 2: Chạy test để thấy fail**

Run: `cd packages/ptalk_core && flutter test test/net/dashboard_client_test.dart`
Expected: FAIL — `DashboardClient`/`ApiUnauthorized` chưa tồn tại.

- [ ] **Step 3: Cài `http` cho test**

Trong `packages/ptalk_core/pubspec.yaml` dưới `dev_dependencies:` (cạnh `flutter_test`) thêm:

```yaml
  http: ^1.2.0
```
Run: `cd packages/ptalk_core && flutter pub get`
(`http/testing.dart` đi kèm gói `http`, không cần dep riêng.)

- [ ] **Step 4: Cài đặt DashboardClient**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Ném khi không xác thực được (401 và refresh thất bại).
class ApiUnauthorized implements Exception {
  final String message;
  ApiUnauthorized([this.message = 'Phiên đăng nhập đã hết hạn']);
  @override
  String toString() => message;
}

/// Ném khi server trả lỗi (>=400, khác 401).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client gọi Dashboard v1: tự gắn Bearer; khi 401 thì refresh rồi thử lại 1 lần.
class DashboardClient {
  DashboardClient({
    required String baseUrl,
    required Future<String?> Function() getAccessToken,
    required Future<String?> Function() refreshToken,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _getAccessToken = getAccessToken,
        _refreshToken = refreshToken,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final Future<String?> Function() _getAccessToken;
  final Future<String?> Function() _refreshToken;
  final http.Client _http;

  /// GET trả JSON object. `path` bắt đầu bằng '/'.
  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    var token = await _getAccessToken();
    var res = await _http.get(uri, headers: _headers(token));

    if (res.statusCode == 401) {
      final fresh = await _refreshToken();
      if (fresh == null) throw ApiUnauthorized();
      res = await _http.get(uri, headers: _headers(fresh));
      if (res.statusCode == 401) throw ApiUnauthorized();
    }

    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
}
```

- [ ] **Step 5: Export**

Trong `packages/ptalk_core/lib/ptalk_core.dart` thêm:

```dart
export 'src/net/dashboard_client.dart';
```

- [ ] **Step 6: Chạy test để thấy pass**

Run: `cd packages/ptalk_core && flutter test test/net/dashboard_client_test.dart`
Expected: All tests passed.

- [ ] **Step 7: Commit**

```bash
git add packages/ptalk_core/lib/src/net/dashboard_client.dart packages/ptalk_core/test/net/dashboard_client_test.dart packages/ptalk_core/lib/ptalk_core.dart packages/ptalk_core/pubspec.yaml packages/ptalk_core/pubspec.lock
git commit -m "feat(core): DashboardClient with bearer auth and 401 refresh-retry"
```

### Task A4: ensureUser() sau login (JIT provisioning)

**Files:** Modify `PTalk_Signature/lib/core/providers.dart`

- [ ] **Step 1: Thêm provider DashboardClient**

Trong `PTalk_Signature/lib/core/providers.dart`, sau `authServiceProvider`, thêm:

```dart
/// Client gọi Dashboard v1, lấy token từ TokenStore, refresh qua AuthService.
final dashboardClientProvider = Provider<DashboardClient>((ref) {
  final store = ref.read(tokenStoreProvider);
  final auth = ref.read(authServiceProvider);
  return DashboardClient(
    baseUrl: ApiConfig.dashboardBaseUrl,
    getAccessToken: () => store.accessToken,
    refreshToken: () async {
      final rt = await store.refreshToken;
      if (rt == null || rt.isEmpty) return null;
      try {
        final res = await auth.refresh(rt);
        await store.saveFromAuthResult(res);
        return res.accessToken;
      } catch (_) {
        return null;
      }
    },
  );
});
```

- [ ] **Step 2: Gọi ensureUser sau khi lưu token**

Trong `LoginController.loginWithSso()`, sau `await _store.saveFromAuthResult(result);` và TRƯỚC `state = LoginSuccess(result);`, chèn:

```dart
      // Kích JIT provisioning: 1 call authed bất kỳ → backend upsert user vào ptalk_auth.
      try {
        await _ensureUser();
      } catch (_) {
        // Không chặn đăng nhập nếu sync lỗi mạng; màn hồ sơ sẽ tự thử lại.
      }
```

Đổi constructor `LoginController` để nhận client và thêm hàm `_ensureUser`. Thay khối class `LoginController` hiện tại bằng:

```dart
class LoginController extends StateNotifier<LoginState> {
  LoginController(this._auth, this._store, this._client) : super(const LoginIdle());

  final AuthService _auth;
  final TokenStore _store;
  final DashboardClient _client;

  Future<void> _ensureUser() => _client.getJson('/api/v1/profile');

  Future<bool> loginWithSso() async {
    state = const LoginInProgress();
    try {
      final result = await _auth.login();
      await _store.saveFromAuthResult(result);
      try {
        await _ensureUser();
      } catch (_) {}
      state = LoginSuccess(result);
      return true;
    } on AuthException catch (e) {
      state = LoginFailure(e.message);
      return false;
    } catch (e) {
      state = LoginFailure('Lỗi không xác định: $e');
      return false;
    }
  }
}
```

Và sửa `loginControllerProvider`:

```dart
final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(
    ref.read(authServiceProvider),
    ref.read(tokenStoreProvider),
    ref.read(dashboardClientProvider),
  );
});
```

- [ ] **Step 3: Phân tích tĩnh**

Run: `cd PTalk_Signature && flutter analyze lib/core/providers.dart`
Expected: "No issues found!" (`ApiConfig`, `DashboardClient` đến từ `package:ptalk_core/ptalk_core.dart` đã import sẵn).

- [ ] **Step 4: Commit**

```bash
git add PTalk_Signature/lib/core/providers.dart
git commit -m "feat(signature): JIT-provision user via /api/v1/profile after SSO login"
```

---

## Phase B — Backend Dashboard (repo Dashboard/dashboard)

> **⏸ HOÃN (quyết định 2026-06-07):** Không thực thi Phase B trong lượt này. App degrade gọn: badge gói lấy từ JWT (Task D1 `subscriptionTierProvider`), thẻ lượt dùng hiện "Chưa có dữ liệu" khi `/api/v1/profile` chưa trả `usageToday` (Task C1 `available`, Task D2). `ensureUser()` vẫn chạy vì `/api/v1/profile` đã tồn tại. Làm Phase B sau khi sẵn sàng deploy backend.
>
> Chạy trong `Dashboard/dashboard/`. Đây là repo git riêng — commit ở đó.

### Task B1: Chấp nhận issuer ptalk-signature

**Files:** Modify `Dashboard/dashboard/src/lib/api-auth.ts`

- [ ] **Step 1: Thêm issuer vào MOBILE_ISSUERS default**

Tìm chuỗi mặc định:

```
"https://auth.ctslab.net/application/o/p-assistant/,https://auth.ctslab.net/application/o/kid-mentor/"
```

Đổi thành (thêm ptalk-signature ở cuối):

```
"https://auth.ctslab.net/application/o/p-assistant/,https://auth.ctslab.net/application/o/kid-mentor/,https://auth.ctslab.net/application/o/ptalk-signature/"
```

- [ ] **Step 2: Build kiểm tra**

Run: `cd Dashboard/dashboard && npx tsc --noEmit`
Expected: không lỗi type liên quan file này.

- [ ] **Step 3: Commit**

```bash
cd Dashboard/dashboard
git add src/lib/api-auth.ts
git commit -m "feat(api): accept ptalk-signature issuer for mobile bearer tokens"
```

### Task B2: /api/v1/profile trả thêm gói + lượt dùng hôm nay

**Files:** Modify `Dashboard/dashboard/src/app/api/v1/profile/route.ts`

- [ ] **Step 1: Mở rộng SELECT lấy subscription_tier**

Trong `selectParent`, đổi SQL SELECT để thêm `subscription_tier`:

```ts
  const [row] = await query<ParentRow>(
    `SELECT username, email, display_name, full_name, phone_number,
            subscription_tier,
            to_char(date_of_birth, 'YYYY-MM-DD') AS date_of_birth
       FROM users WHERE id = $1`,
    [userId],
  );
```
Và thêm `subscription_tier: string | null;` vào type `ParentRow`.

- [ ] **Step 2: Thêm hàm đếm lượt dùng hôm nay**

Trên `selectParent`, thêm:

```ts
const QUOTA_BY_TIER: Record<string, number | null> = {
  basic: 20, pro: 500, ultra: null, admin: null,
};

async function usageToday(userId: string, tier: string | null) {
  // request_logs là bảng tổng hợp theo ngày: (user_id, request_date DATE, request_count).
  const [r] = await query<{ used: string }>(
    `SELECT COALESCE(SUM(request_count), 0)::text AS used FROM request_logs
      WHERE user_id = $1 AND request_date = CURRENT_DATE`,
    [userId],
  );
  const used = parseInt(r?.used ?? '0', 10);
  const quota = QUOTA_BY_TIER[tier ?? 'basic'] ?? null;
  // Reset đầu ngày kế tiếp (server local time).
  const now = new Date();
  const reset = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  return { used, quota, resetsAt: reset.toISOString() };
}
```

> Schema đã xác nhận: `request_logs(id, user_id, request_date, request_count)`. Nếu cách đếm lượt của CloudPTalk khác (kiểm tra `\d request_logs` + nơi worker ghi), chỉnh cho khớp.

- [ ] **Step 3: Đưa vào response GET**

Trong `GET`, thay đoạn trả về:

```ts
    const row = await selectParent(user.id);
    if (!row) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const usage = await usageToday(user.id, row.subscription_tier);
    return NextResponse.json({
      profile: {
        ...rowToJson(row),
        subscriptionTier: row.subscription_tier ?? "basic",
        usageToday: usage.used,
        quota: usage.quota,
        resetsAt: usage.resetsAt,
      },
    });
```

- [ ] **Step 4: Build kiểm tra**

Run: `cd Dashboard/dashboard && npx tsc --noEmit`
Expected: không lỗi.

- [ ] **Step 5: Kiểm thử thủ công (nếu có token)**

Run: `curl -s -H "Authorization: Bearer <token>" https://dashboard.ctslab.net/api/v1/profile | jq`
Expected: JSON có `profile.subscriptionTier`, `profile.usageToday`, `profile.quota`, `profile.resetsAt`.

- [ ] **Step 6: Commit**

```bash
cd Dashboard/dashboard
git add src/app/api/v1/profile/route.ts
git commit -m "feat(api): include subscription tier + today usage in /api/v1/profile"
```

---

## Phase C — Models, Repository, ActiveChildStore (ptalk_core)

### Task C1: Models + label helpers

**Files:**
- Create: `packages/ptalk_core/lib/src/data/models.dart`
- Test: `packages/ptalk_core/test/data/models_test.dart`

- [ ] **Step 1: Viết test thất bại**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  test('ParentProfile.fromJson', () {
    final p = ParentProfile.fromJson({
      'fullName': 'Lê Hoàng Nam',
      'phone': '0901234567',
      'email': 'namnx@ptalk.vn',
      'subscriptionTier': 'pro',
    });
    expect(p.fullName, 'Lê Hoàng Nam');
    expect(p.phone, '0901234567');
    expect(p.subscriptionTier, 'pro');
  });

  test('ChildProfile map nhãn lớp / bộ sách / quan hệ', () {
    final c = ChildProfile.fromJson({
      'id': 'abc',
      'username': 'child_x',
      'fullName': 'Lê Hoàng An',
      'grade': '4',
      'dateOfBirth': '2016-05-12',
      'hometown': 'Thanh Hoá',
      'curriculum': 'ket_noi_tri_thuc',
      'relationship': 'father',
    });
    expect(c.gradeLabel, 'Lớp 4');
    expect(c.curriculumLabel, 'Kết nối tri thức');
    expect(c.relationshipLabel, 'Bố');
  });

  test('UsageToday.fromJson với quota null = không giới hạn', () {
    final u = UsageToday.fromJson(
        {'usageToday': 12, 'quota': null, 'resetsAt': '2026-06-08T00:00:00.000Z'});
    expect(u.used, 12);
    expect(u.isUnlimited, true);
    expect(u.available, true);
  });

  test('UsageToday.fromJson thiếu field (backend chưa cập nhật) = không available', () {
    final u = UsageToday.fromJson({'fullName': 'x'}); // không có usageToday
    expect(u.available, false);
  });
}
```

- [ ] **Step 2: Chạy test để thấy fail**

Run: `cd packages/ptalk_core && flutter test test/data/models_test.dart`
Expected: FAIL — model chưa tồn tại.

- [ ] **Step 3: Cài đặt models**

```dart
String? _s(dynamic v) => v == null ? null : v.toString();

class ParentProfile {
  final String fullName;
  final String? phone;
  final String email;
  final String subscriptionTier; // basic | pro | ultra | admin
  ParentProfile({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.subscriptionTier,
  });
  factory ParentProfile.fromJson(Map<String, dynamic> j) => ParentProfile(
        fullName: _s(j['fullName']) ?? _s(j['displayName']) ?? '',
        phone: _s(j['phone']),
        email: _s(j['email']) ?? '',
        subscriptionTier: _s(j['subscriptionTier']) ?? 'basic',
      );
}

const _curriculumLabels = {
  'chan_troi_sang_tao': 'Chân trời sáng tạo',
  'canh_dieu': 'Cánh diều',
  'ket_noi_tri_thuc': 'Kết nối tri thức',
};
const _relationshipLabels = {
  'father': 'Bố',
  'mother': 'Mẹ',
  'grandparent': 'Ông/Bà',
  'guardian': 'Người giám hộ',
  'other': 'Khác',
};

class ChildProfile {
  final String id;
  final String username;
  final String fullName;
  final String? grade;
  final String? dateOfBirth;
  final String? hometown;
  final String? curriculum;
  final String? relationship;
  ChildProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.grade,
    this.dateOfBirth,
    this.hometown,
    this.curriculum,
    this.relationship,
  });
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: _s(j['id']) ?? '',
        username: _s(j['username']) ?? '',
        fullName: _s(j['fullName']) ?? '',
        grade: _s(j['grade']),
        dateOfBirth: _s(j['dateOfBirth']),
        hometown: _s(j['hometown']),
        curriculum: _s(j['curriculum']),
        relationship: _s(j['relationship']),
      );

  String get gradeLabel => (grade == null || grade!.isEmpty) ? '—' : 'Lớp $grade';
  String get curriculumLabel => _curriculumLabels[curriculum] ?? '—';
  String get relationshipLabel => _relationshipLabels[relationship] ?? '—';
}

class UsageToday {
  final int used;
  final int? quota; // null = không giới hạn
  final String? resetsAt;
  final bool available; // false = backend chưa trả field lượt dùng (Phase B chưa làm)
  UsageToday(
      {required this.used,
      required this.quota,
      this.resetsAt,
      this.available = true});
  bool get isUnlimited => quota == null;
  double get fraction =>
      (quota == null || quota == 0) ? 0 : (used / quota!).clamp(0, 1);
  factory UsageToday.fromJson(Map<String, dynamic> j) => UsageToday(
        used: (j['usageToday'] as num?)?.toInt() ?? 0,
        quota: (j['quota'] as num?)?.toInt(),
        resetsAt: _s(j['resetsAt']),
        available: j.containsKey('usageToday'),
      );
}

/// Bé đang dùng app — lưu local, đính vào phiên voice.
class ActiveChild {
  final String childId;
  final String username; // = device_id gửi CloudPTalk
  final String fullName;
  ActiveChild({required this.childId, required this.username, required this.fullName});
}
```

- [ ] **Step 4: Export**

Trong `packages/ptalk_core/lib/ptalk_core.dart` thêm:

```dart
export 'src/data/models.dart';
```

- [ ] **Step 5: Chạy test để thấy pass**

Run: `cd packages/ptalk_core && flutter test test/data/models_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add packages/ptalk_core/lib/src/data/models.dart packages/ptalk_core/test/data/models_test.dart packages/ptalk_core/lib/ptalk_core.dart
git commit -m "feat(core): profile/child/usage models with VN label helpers"
```

### Task C2: ProfileRepository

**Files:**
- Create: `packages/ptalk_core/lib/src/data/profile_repository.dart`
- Test: `packages/ptalk_core/test/data/profile_repository_test.dart`

- [ ] **Step 1: Viết test thất bại**

```dart
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
```

- [ ] **Step 2: Chạy test để thấy fail**

Run: `cd packages/ptalk_core && flutter test test/data/profile_repository_test.dart`
Expected: FAIL — `ProfileRepository` chưa tồn tại.

- [ ] **Step 3: Cài đặt repository**

```dart
import 'net/dashboard_client.dart';
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
```

> Lưu ý import: file ở `lib/src/data/`, nên import `net/dashboard_client.dart` phải là `../net/dashboard_client.dart`. Sửa 2 dòng import đầu thành `import '../net/dashboard_client.dart';` và `import 'models.dart';`.

- [ ] **Step 4: Export**

Trong `packages/ptalk_core/lib/ptalk_core.dart` thêm:

```dart
export 'src/data/profile_repository.dart';
```

- [ ] **Step 5: Chạy test để thấy pass**

Run: `cd packages/ptalk_core && flutter test test/data/profile_repository_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add packages/ptalk_core/lib/src/data/profile_repository.dart packages/ptalk_core/test/data/profile_repository_test.dart packages/ptalk_core/lib/ptalk_core.dart
git commit -m "feat(core): ProfileRepository over Dashboard v1 endpoints"
```

### Task C3: ActiveChildStore

**Files:**
- Create: `packages/ptalk_core/lib/src/state/active_child_store.dart`
- Test: `packages/ptalk_core/test/state/active_child_store_test.dart`

- [ ] **Step 1: Viết test thất bại** (dùng FlutterSecureStorage mock in-memory)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lưu và đọc lại bé active', () async {
    final store = ActiveChildStore();
    expect(await store.read(), isNull);

    await store.save(ActiveChild(
        childId: '1', username: 'child_1', fullName: 'Bé An'));
    final got = await store.read();

    expect(got!.childId, '1');
    expect(got.username, 'child_1');
    expect(got.fullName, 'Bé An');
  });

  test('clear xoá bé active', () async {
    final store = ActiveChildStore();
    await store.save(ActiveChild(childId: '1', username: 'u', fullName: 'n'));
    await store.clear();
    expect(await store.read(), isNull);
  });
}
```

- [ ] **Step 2: Chạy test để thấy fail**

Run: `cd packages/ptalk_core && flutter test test/state/active_child_store_test.dart`
Expected: FAIL — `ActiveChildStore` chưa tồn tại.

- [ ] **Step 3: Cài đặt store**

```dart
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
```

- [ ] **Step 4: Export**

Trong `packages/ptalk_core/lib/ptalk_core.dart` thêm:

```dart
export 'src/state/active_child_store.dart';
```

- [ ] **Step 5: Chạy test để thấy pass**

Run: `cd packages/ptalk_core && flutter test test/state/active_child_store_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Chạy toàn bộ test core + analyze**

Run: `cd packages/ptalk_core && flutter test && dart analyze`
Expected: All tests passed; No issues found.

- [ ] **Step 7: Commit**

```bash
git add packages/ptalk_core/lib/src/state/active_child_store.dart packages/ptalk_core/test/state/active_child_store_test.dart packages/ptalk_core/lib/ptalk_core.dart
git commit -m "feat(core): ActiveChildStore for locally-selected child"
```

---

## Phase D — UI (PTalk_Signature)

### Task D1: Providers cho màn tài khoản

**Files:** Create `PTalk_Signature/lib/account/account_providers.dart`

- [ ] **Step 1: Tạo providers**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../settings/subscription.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepository(ref.read(dashboardClientProvider)));

/// Gói cước suy ra từ JWT (claim subscription_tier/is_superuser) — hoạt động
/// không cần backend Phase B. Trả 'basic' nếu chưa có token.
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  final token = await ref.read(tokenStoreProvider).accessToken;
  return resolveTier(token);
});

final activeChildStoreProvider =
    Provider<ActiveChildStore>((ref) => ActiveChildStore());

final parentProfileProvider = FutureProvider<ParentProfile>(
    (ref) => ref.read(profileRepositoryProvider).getParent());

final usageTodayProvider = FutureProvider<UsageToday>(
    (ref) => ref.read(profileRepositoryProvider).getUsageToday());

final childrenProvider = FutureProvider<List<ChildProfile>>(
    (ref) => ref.read(profileRepositoryProvider).getChildren());

final childDetailProvider = FutureProvider.family<ChildProfile, String>(
    (ref, id) => ref.read(profileRepositoryProvider).getChild(id));

/// Bé active hiện tại (đọc từ store). Ghi qua [setActiveChild].
final activeChildProvider = FutureProvider<ActiveChild?>(
    (ref) => ref.read(activeChildStoreProvider).read());

Future<void> setActiveChild(WidgetRef ref, ChildProfile c) async {
  await ref.read(activeChildStoreProvider).save(ActiveChild(
        childId: c.id,
        username: c.username,
        fullName: c.fullName,
      ));
  ref.invalidate(activeChildProvider);
}
```

- [ ] **Step 2: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/account/account_providers.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add PTalk_Signature/lib/account/account_providers.dart
git commit -m "feat(signature): account providers (profile, children, active child)"
```

### Task D2: Màn /account (hub)

**Files:** Create `PTalk_Signature/lib/account/account_screen.dart`

- [ ] **Step 1: Tạo màn hình**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../settings/subscription.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final parentAsync = ref.watch(parentProfileProvider);
    final usageAsync = ref.watch(usageTodayProvider);
    final childrenAsync = ref.watch(childrenProvider);
    final tier = ref.watch(subscriptionTierProvider).asData?.value ?? 'basic';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Quản lý tài khoản'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(parentProfileProvider);
            ref.invalidate(usageTodayProvider);
            ref.invalidate(childrenProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _accountCard(context, parentAsync, tier, accent),
              const SizedBox(height: 16),
              _sectionLabel('LƯỢT SỬ DỤNG HÔM NAY', accent),
              _usageCard(usageAsync, accent),
              const SizedBox(height: 16),
              _sectionLabel('TÀI KHOẢN', accent),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Thông tin phụ huynh'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/account/parent'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.child_care_outlined),
                    title: const Text('Hồ sơ các bé'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(childrenAsync.maybeWhen(
                          data: (l) => '${l.length} bé', orElse: () => '')),
                      const Icon(Icons.chevron_right),
                    ]),
                    onTap: () => context.push('/account/children'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () => _openStore(),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('ĐẶT MUA THIẾT BỊ'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('ĐĂNG XUẤT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t, Color accent) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(t,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5)),
      );

  Widget _accountCard(BuildContext context,
      AsyncValue<ParentProfile> async, String tier, Color accent) {
    return Card(
      child: async.when(
        loading: () => const ListTile(
            leading: CircularProgressIndicator(), title: Text('Đang tải…')),
        error: (_, __) => ListTile(
          leading: const Icon(Icons.error_outline, color: AppColors.error),
          title: const Text('Không tải được tài khoản'),
          subtitle: const Text('Kéo xuống để thử lại'),
        ),
        data: (p) {
          final plan = SubPlan.all.firstWhere(
              (s) => s.tier == tier,
              orElse: () => SubPlan.all.first);
          return ListTile(
            leading: CircleAvatar(
                backgroundColor: accent,
                child: const Icon(Icons.person, color: Colors.white)),
            title: Text(p.fullName.isEmpty ? p.email : p.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.email),
            trailing: Chip(
              backgroundColor: AppColors.kidBadgeBg,
              label: Text('★ ${plan.name}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ),
          );
        },
      ),
    );
  }

  Widget _usageCard(AsyncValue<UsageToday> async, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Không tải được lượt dùng'),
          data: (u) {
            if (!u.available) {
              return Row(children: const [
                Icon(Icons.hourglass_empty, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Chưa có dữ liệu lượt dùng',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ]);
            }
            if (u.isUnlimited) {
              return Row(children: [
                Icon(Icons.all_inclusive, color: accent),
                const SizedBox(width: 8),
                Text('${u.used} câu hỏi hôm nay · Không giới hạn'),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${u.used} / ${u.quota} câu hỏi',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: u.fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.dividerLine,
                    color: accent),
              ),
              const SizedBox(height: 6),
              Text('Còn lại ${(u.quota! - u.used).clamp(0, u.quota!)} lượt',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]);
          },
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.parse('${ApiConfig.dashboardBaseUrl}/store');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để sử dụng tài khoản.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tokenStoreProvider).clear();
      await ref.read(activeChildStoreProvider).clear();
      if (context.mounted) context.go('/login');
    }
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/account/account_screen.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add PTalk_Signature/lib/account/account_screen.dart
git commit -m "feat(signature): account hub screen (plan, usage, nav, logout)"
```

### Task D3: Màn /account/parent (chỉ xem)

**Files:** Create `PTalk_Signature/lib/account/parent_screen.dart`

- [ ] **Step 1: Tạo màn hình**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final async = ref.watch(parentProfileProvider);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Thông tin phụ huynh'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              const Text('Không tải được thông tin'),
              TextButton(
                  onPressed: () => ref.invalidate(parentProfileProvider),
                  child: const Text('Thử lại')),
            ]),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: Column(children: [
                  CircleAvatar(
                      radius: 36,
                      backgroundColor: accent,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 40)),
                  const SizedBox(height: 12),
                  Text(p.fullName.isEmpty ? p.email : p.fullName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Chủ tài khoản',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(children: [
                  _row('Họ và tên', p.fullName.isEmpty ? '—' : p.fullName),
                  const Divider(height: 1),
                  _row('Số điện thoại', (p.phone?.isEmpty ?? true) ? '—' : p.phone!),
                  const Divider(height: 1),
                  _row('Email', p.email),
                ]),
              ),
              const SizedBox(height: 16),
              const _ReadOnlyHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
        title: Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _ReadOnlyHint extends StatelessWidget {
  const _ReadOnlyHint();
  @override
  Widget build(BuildContext context) => Row(children: const [
        Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Thông tin đồng bộ từ hệ thống. Để chỉnh sửa, dùng Web Dashboard.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ]);
}
```

- [ ] **Step 2: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/account/parent_screen.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add PTalk_Signature/lib/account/parent_screen.dart
git commit -m "feat(signature): read-only parent info screen"
```

### Task D4: Màn /account/children (danh sách + chọn bé active)

**Files:** Create `PTalk_Signature/lib/account/children_screen.dart`

- [ ] **Step 1: Tạo màn hình**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final childrenAsync = ref.watch(childrenProvider);
    final activeAsync = ref.watch(activeChildProvider);
    final activeId = activeAsync.asData?.value?.childId;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Hồ sơ các bé'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: TextButton(
                onPressed: () => ref.invalidate(childrenProvider),
                child: const Text('Không tải được. Thử lại')),
          ),
          data: (children) {
            if (children.isEmpty) {
              return const _Empty();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _label('TẤT CẢ CÁC BÉ (${children.length})', accent),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _childTile(context, ref, children[i],
                            isActive: children[i].id == activeId, accent: accent),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: const [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chọn bé đang dùng để AI dạy đúng lớp và bộ sách của bé đó.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String t, Color accent) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: TextStyle(
                color: accent, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _childTile(BuildContext context, WidgetRef ref, ChildProfile c,
      {required bool isActive, required Color accent}) {
    return ListTile(
      leading: Icon(
          isActive ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isActive ? accent : AppColors.textMuted),
      title: Text(c.fullName.isEmpty ? 'Bé' : c.fullName),
      subtitle: Text('${c.gradeLabel} · ${c.relationshipLabel}'),
      trailing: IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () => context.push('/account/children/${c.id}'),
      ),
      onTap: () async {
        await setActiveChild(ref, c);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đang dùng app với hồ sơ ${c.fullName}')),
          );
        }
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.child_care_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Chưa có hồ sơ bé',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Thêm hồ sơ bé trên Web Dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
}
```

- [ ] **Step 2: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/account/children_screen.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add PTalk_Signature/lib/account/children_screen.dart
git commit -m "feat(signature): children list + select active child"
```

### Task D5: Màn /account/children/:id (chi tiết bé)

**Files:** Create `PTalk_Signature/lib/account/child_detail_screen.dart`

- [ ] **Step 1: Tạo màn hình**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final async = ref.watch(childDetailProvider(childId));
    final activeId = ref.watch(activeChildProvider).asData?.value?.childId;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Thông tin bé'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: TextButton(
                onPressed: () => ref.invalidate(childDetailProvider(childId)),
                child: const Text('Không tải được. Thử lại')),
          ),
          data: (c) {
            final isActive = c.id == activeId;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Center(
                  child: Column(children: [
                    CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.kidBadgeBg,
                        child: Icon(Icons.child_care, color: accent, size: 40)),
                    const SizedBox(height: 12),
                    Text(c.fullName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (isActive) ...[
                      const SizedBox(height: 6),
                      Chip(
                        backgroundColor: AppColors.kidBadgeBg,
                        label: Text('✓ Đang dùng',
                            style: TextStyle(
                                color: accent, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(children: [
                    _row('Họ và tên', c.fullName.isEmpty ? '—' : c.fullName),
                    const Divider(height: 1),
                    _row('Lớp', c.gradeLabel),
                    const Divider(height: 1),
                    _row('Ngày sinh', c.dateOfBirth ?? '—'),
                    const Divider(height: 1),
                    _row('Quê quán', c.hometown ?? '—'),
                    const Divider(height: 1),
                    _row('Bộ sách', c.curriculumLabel),
                    const Divider(height: 1),
                    _row('Quan hệ', c.relationshipLabel),
                  ]),
                ),
                const SizedBox(height: 16),
                if (!isActive)
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () async {
                        await setActiveChild(ref, c);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Đang dùng app với hồ sơ ${c.fullName}')));
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('CHỌN BÉ NÀY DÙNG APP'),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(children: const [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Thông tin đồng bộ từ hệ thống.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
        title: Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
```

- [ ] **Step 2: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/account/child_detail_screen.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add PTalk_Signature/lib/account/child_detail_screen.dart
git commit -m "feat(signature): read-only child detail + select active"
```

### Task D6: Routes + lối vào (avatar Home, link Settings)

**Files:**
- Modify: `PTalk_Signature/lib/router.dart`
- Modify: `PTalk_Signature/lib/screens/main_voice_screen.dart`
- Modify: `PTalk_Signature/lib/screens/settings_screen.dart`

- [ ] **Step 1: Thêm 4 route**

Trong `PTalk_Signature/lib/router.dart`, thêm import:

```dart
import 'account/account_screen.dart';
import 'account/parent_screen.dart';
import 'account/children_screen.dart';
import 'account/child_detail_screen.dart';
```

Và trong danh sách `routes:` (sau route `/settings`) thêm:

```dart
    GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
    GoRoute(path: '/account/parent', builder: (_, _) => const ParentScreen()),
    GoRoute(path: '/account/children', builder: (_, _) => const ChildrenScreen()),
    GoRoute(
        path: '/account/children/:id',
        builder: (_, s) =>
            ChildDetailScreen(childId: s.pathParameters['id']!)),
```

- [ ] **Step 2: Thêm avatar vào header màn Home**

Mở `PTalk_Signature/lib/screens/main_voice_screen.dart`, tìm IconButton/khu vực header có nút back hoặc settings. Thêm một `IconButton` avatar điều hướng `/account`:

```dart
IconButton(
  icon: const Icon(Icons.account_circle_outlined),
  tooltip: 'Tài khoản',
  onPressed: () => context.push('/account'),
),
```

(Đặt cạnh nút settings/back hiện có. Đảm bảo `import 'package:go_router/go_router.dart';` đã có trong file — nếu chưa, thêm.)

- [ ] **Step 3: Đổi mục TÀI KHOẢN trong Settings thành link sang /account**

Trong `PTalk_Signature/lib/screens/settings_screen.dart`, thay nguyên khối `_section('TÀI KHOẢN', accent)` + `FutureBuilder<List<String?>>(...)` Card phía dưới nó bằng:

```dart
          _section('TÀI KHOẢN', accent),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: accent,
                  child: const Icon(Icons.person, color: Colors.white)),
              title: const Text('Quản lý tài khoản'),
              subtitle: const Text('Hồ sơ phụ huynh, các bé, gói cước'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account'),
            ),
          ),
```

(Giữ nguyên phần "Gói cước & hạn mức" nếu muốn, hoặc bỏ vì đã có trong /account — tuỳ, không bắt buộc. Phần ĐĂNG NHẬP/ĐĂNG XUẤT ở cuối Settings giữ nguyên.)

- [ ] **Step 4: Analyze toàn app**

Run: `cd PTalk_Signature && flutter analyze`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add PTalk_Signature/lib/router.dart PTalk_Signature/lib/screens/main_voice_screen.dart PTalk_Signature/lib/screens/settings_screen.dart
git commit -m "feat(signature): wire account routes + entry points (home avatar, settings)"
```

---

## Phase E — Đấu bé active vào phiên voice

### Task E1: device_id = username bé active

**Files:**
- Modify: `PTalk_Signature/lib/voice/voice_controller.dart`
- Modify: `PTalk_Signature/lib/voice/streaming_voice_client.dart`

- [ ] **Step 1: Đọc cách handshake hiện tại**

Run: `cd PTalk_Signature && grep -n "device_id\|deviceId\|firmware_version\|StreamingVoiceClient(" lib/voice/streaming_voice_client.dart lib/voice/voice_controller.dart`
Mục tiêu: tìm nơi `device_id` được đặt (hiện là email/username tài khoản).

- [ ] **Step 2: Thêm tham số deviceIdOverride cho client**

Trong `streaming_voice_client.dart`, thêm field tuỳ chọn vào constructor `StreamingVoiceClient` và dùng nó cho `device_id` trong payload handshake:

```dart
  final String? deviceIdOverride;
```
Trong handshake JSON, đổi `"device_id": <giá trị hiện tại>` thành:

```dart
'device_id': deviceIdOverride ?? <giá trị hiện tại>,
```

- [ ] **Step 3: Truyền username bé active khi tạo client**

Trong `voice_controller.dart`, ở `_ensureClient()` (nơi `StreamingVoiceClient(...)` được tạo), đọc bé active và truyền vào:

```dart
    final active = await ActiveChildStore().read();
    _client = StreamingVoiceClient(
      // ...các tham số hiện có...
      deviceIdOverride: active?.username,
    );
```
(Thêm `import 'package:ptalk_core/ptalk_core.dart';` nếu chưa có.)

- [ ] **Step 4: Analyze**

Run: `cd PTalk_Signature && flutter analyze lib/voice`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add PTalk_Signature/lib/voice/streaming_voice_client.dart PTalk_Signature/lib/voice/voice_controller.dart
git commit -m "feat(signature): route voice session to active child's id for AI personalization"
```

---

## Phase F — Kiểm thử & nghiệm thu

### Task F1: Test + analyze toàn workspace

- [ ] **Step 1: Test core**

Run: `cd packages/ptalk_core && flutter test`
Expected: All tests passed.

- [ ] **Step 2: Analyze app**

Run: `cd PTalk_Signature && flutter analyze`
Expected: "No issues found!"

### Task F2: Nghiệm thu thủ công (chạy release)

> Chạy `flutter run --release` (theo memory: debug/JIT gây jank và iOS không chạy khi thoát Mac).

- [ ] **Step 1: Đăng nhập → kiểm DB**

Đăng nhập SSO trong app. Trên server:
Run: `docker exec cts-dashboard-db psql -U postgres -d ptalk_auth -c "SELECT email, authentik_user_id, last_login_at FROM users ORDER BY updated_at DESC LIMIT 5;"`
Expected: có dòng user vừa đăng nhập với `authentik_user_id` không NULL.

- [ ] **Step 2: Màn /account**

Mở avatar → `/account`. Expected: hiện đúng tên + badge gói + "x/quota câu hỏi hôm nay".

- [ ] **Step 3: Phụ huynh & bé**

Vào "Thông tin phụ huynh" (đúng SĐT/email từ DB) và "Hồ sơ các bé" (đúng danh sách). Mở chi tiết 1 bé: lớp/ngày sinh/quê quán/bộ sách/quan hệ đúng DB.

- [ ] **Step 4: Bé active → AI**

Chọn 1 bé khác → bắt đầu phiên voice. Expected: handshake gửi `device_id` = username bé đó (kiểm log app/CloudPTalk), AI cá nhân hoá theo lớp/bộ sách của bé.

- [ ] **Step 5: Commit cuối (nếu có chỉnh nhỏ khi nghiệm thu)**

```bash
git add -A && git commit -m "test: manual acceptance fixes for account/profile sync"
```

---

## Definition of Done

1. Login → `users` có record `authentik_user_id` mới (Task F2.1).
2. `/account` hiện đúng tên + gói + lượt dùng từ DB (F2.2).
3. Màn phụ huynh & bé hiện đúng dữ liệu DB, chỉ xem (F2.3).
4. Chọn bé khác → phiên voice dùng đúng `device_id` của bé (F2.4).
5. `flutter analyze` sạch + test core xanh (F1).
