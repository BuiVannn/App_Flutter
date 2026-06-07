# Thiết kế: Đồng bộ tài khoản + Màn hồ sơ (PTalk Signature Flutter)

- **Ngày:** 2026-06-07
- **Phạm vi:** `App_Flutter` (`packages/ptalk_core`, `PTalk_Signature`) + một thay đổi nhỏ ở backend Dashboard.
- **Trạng thái:** Đã duyệt thiết kế — chờ review spec trước khi lập plan.

## 1. Bối cảnh & vấn đề (gốc rễ)

Các app cũ (KidMentor, PTalk Signature Kotlin) đăng nhập SSO nhưng **không đẩy user lên DB chung** `ptalk_auth`, nên dữ liệu không đồng bộ giữa các app. Chỉ P-Connect (Kotlin) được đấu vào Dashboard v1 API.

Bản Flutter hiện tại **lặp lại đúng lỗi này**: `ptalk_core` chỉ có tầng SSO (`AuthService` → `TokenStore`), **không có API client** gọi backend chung. `LoginController.loginWithSso()` lấy token rồi lưu local là hết.

Backend Dashboard đã có **JIT provisioning**: gọi bất kỳ `/api/v1/*` nào với Bearer token hợp lệ → tự lookup theo `sub`/`email`, chưa có thì `INSERT` vào `ptalk_auth.users`. Vì vậy chỉ cần app gọi 1 endpoint authed sau login là user tự đồng bộ.

## 2. Mục tiêu / Không nằm trong phạm vi

**Mục tiêu**
- `ptalk_core` có tầng data đồng bộ với Dashboard v1 (dùng lại cho cả 3 app Flutter sau này).
- User đăng nhập PTalk Signature → có mặt trong `ptalk_auth` (JIT provision).
- 4 màn hồ sơ **chỉ xem**, dữ liệu lấy từ DB chung.
- Chọn "bé đang dùng app" để AI dạy đúng lớp/bộ sách.

**Không nằm trong phạm vi**
- Sửa hồ sơ phụ huynh/bé trên app (chỉ xem; chỉnh sửa qua Web Dashboard).
- Migrate KidMentor / P_Connect sang Flutter (chưa làm ở spec này, nhưng tầng `ptalk_core` thiết kế để dùng lại).
- Tách OIDC client `ptalk-signature` (xử lý riêng; JIT vẫn chạy theo `sub`+`email` dù tạm mượn `kid-mentor`).

## 3. Quyết định đã chốt

1. **Lối vào:** avatar/icon người dùng ở góc phải màn Home (và Mode-select) → `/account`. Mục "Tài khoản" cũ trong Settings đổi thành 1 dòng link sang `/account` (tránh trùng lặp).
2. **Bé active:** lưu local (`ActiveChildStore`), đính kèm hồ sơ bé (tên/lớp/bộ sách) vào mỗi phiên gọi CloudPTalk. Không thêm backend.

## 4. Kiến trúc

```
PTalk_Signature (UI)
   │  Riverpod providers
   ▼
ptalk_core
   ├─ auth/        AuthService (SSO)  · TokenStore (token local)
   ├─ net/         DashboardClient (Bearer + refresh 401)        ← MỚI
   ├─ data/        ProfileRepository  · models                   ← MỚI
   └─ state/       ActiveChildStore (local)                      ← MỚI
        │
        ├─ Dashboard v1 API  (identity, profile, children)  → ptalk_auth
        └─ CloudPTalk (voice websocket)  ← đính activeChild context
```

Nguyên tắc tách bạch: **Dashboard v1** lo identity/profile (đồng bộ), **CloudPTalk** chỉ lo voice. Không trộn như app cũ.

## 5. Bốn màn hình (chỉ xem, trừ chọn bé active)

Dùng `GradientBackground` + `GlassHeader` + `Card`/`ListTile` + section header accent (đồng nhất app). Mọi màn có trạng thái loading / lỗi / rỗng.

### 5.1 `/account` — Quản lý tài khoản (hub)
- Thẻ tài khoản: avatar + `full_name` + badge gói (`subscription_tier`: Cơ Bản/Pro/Ultra).
- Lượt dùng hôm nay: `usage_today / quota` + thanh tiến trình + giờ đặt lại.
- Thẻ điều hướng: "Thông tin phụ huynh" ›, "Hồ sơ các bé (N bé)" ›.
- Nút "Đặt mua thiết bị": mở URL store bên ngoài qua `url_launcher` (mặc định `https://dashboard.ctslab.net`, cấu hình qua build config).
- Nút "Đăng xuất" (outline đỏ, dialog xác nhận → `TokenStore.clear()` → `/login`).

### 5.2 `/account/parent` — Thông tin phụ huynh
- Avatar lớn + tên + "Chủ tài khoản".
- Bảng: Họ và tên, Số điện thoại, Email — từ `users.full_name / phone_number / email`.
- Ghi chú read-only: "Thông tin đồng bộ từ hệ thống. Để chỉnh sửa, dùng Web Dashboard."

### 5.3 `/account/children` — Hồ sơ các bé
- Thẻ "Bé đang dùng app" (nổi bật, viền accent) — bé active hiện tại.
- Danh sách bé (radio ◉/○): tên · lớp · quan hệ; chạm hàng = chọn active; chạm › = mở chi tiết.
- Ghi chú: "Chọn bé đang dùng để AI dạy đúng lớp và bộ sách của bé đó."

### 5.4 `/account/children/:id` — Thông tin bé
- Avatar + tên + badge "Đang dùng" nếu active.
- Bảng: Họ và tên, Lớp, Ngày sinh, Quê quán, Bộ sách, Quan hệ với phụ huynh — từ `users.full_name/grade/date_of_birth/hometown/curriculum` + `user_relationships.relationship_type`.
- Nút "Chọn bé này dùng app" (ẩn nếu đã active) + ghi chú read-only.

## 6. Mô hình dữ liệu (ptalk_core/data/models)

- `ParentProfile { id, fullName, phone, email, subscriptionTier }`
- `ChildProfile { id, fullName, grade, dateOfBirth, hometown, curriculum, relationshipType }`
- `UsageToday { used, quota /* null = không giới hạn */, resetsAt }`
- `ActiveChild { childId, fullName, grade, curriculum }` (local)

## 7. Hợp đồng API

**Đã có:** `GET /api/v1/profile`, `GET /api/v1/children`, `GET /api/v1/children/[id]`.

**Cần bổ sung (backend Dashboard):**
- B1. Thêm `ptalk-signature` vào `MOBILE_ISSUERS` (`src/lib/api-auth.ts`).
- B2. "Lượt dùng hôm nay": nhồi `usage_today` + `quota` + `resets_at` vào response `/api/v1/profile` (gộp để giảm round-trip; đếm từ `request_logs` của user trong ngày, quota theo gói: Basic 20 / Pro 500 / Ultra null).
- B3. Xác nhận `/api/v1/profile` trả `full_name, phone_number, email, subscription_tier`; `/children` trả `grade` + `relationship_type`.

`DashboardClient`: baseUrl cấu hình qua build config; tự gắn `Authorization: Bearer <access>` từ `TokenStore`; khi 401 → `AuthService.refresh()` rồi thử lại 1 lần; thất bại → điều hướng `/login`.

## 8. Luồng bé active → voice

`ActiveChildStore` lưu `childId` (secure storage/prefs). `voice_controller`/`streaming_voice_client` đọc `activeChildContext()` và đính tên/lớp/bộ sách vào tham số phiên CloudPTalk, để AI xưng hô và dạy đúng. Khi chưa chọn bé → không đính context (hành vi mặc định như hiện tại).

## 9. Trạng thái lỗi / rỗng / loading

- Chưa đăng nhập: `/account` điều hướng về `/login` (guard).
- Lỗi mạng: thẻ hiển thị "Không tải được, thử lại" + nút Retry.
- Không có bé nào: màn Hồ sơ bé hiện empty state ("Chưa có hồ sơ bé. Thêm bé trên Web Dashboard.").
- Ultra/không giới hạn: thanh lượt dùng hiện "Không giới hạn" thay vì progress.

## 10. Kiểm thử

- Unit: `AuthResult` parse claims; `ProfileRepository` map JSON→model; `ActiveChildStore` lưu/đọc; `DashboardClient` gắn header + retry 401 (mock http).
- Widget: 4 màn render đúng từ model giả; empty/error states; nút chọn bé đổi trạng thái.
- Tích hợp (thủ công): login thật → kiểm `ptalk_auth.users` có record; đổi bé active → phiên voice dùng đúng lớp.

## 11. Các bước triển khai (tóm tắt — chi tiết ở plan)

- **A. Nền tảng (`ptalk_core`):** A1 `DashboardClient`; A2 `ensureUser()` sau login (JIT).
- **B. Backend:** B1 MOBILE_ISSUERS; B2 usage endpoint; B3 xác nhận field profile/children.
- **C. Data (`ptalk_core`):** C1 models; C2 `ProfileRepository`; C3 `ActiveChildStore` + provider.
- **D. UI (`PTalk_Signature`):** D1–D4 bốn màn; D5 avatar Home + sửa Settings; D6 thêm route.
- **E. Voice:** E1 đính active child vào phiên CloudPTalk.
- **F. Verify:** theo mục 12.

## 12. Tiêu chí hoàn thành (Definition of Done)

1. Login PTalk Signature → `SELECT * FROM users WHERE authentik_user_id=<sub>` có record mới.
2. `/account` hiện đúng tên + gói + lượt dùng hôm nay từ DB.
3. Màn phụ huynh & bé hiện đúng dữ liệu DB; đều chỉ xem.
4. Chọn "Bé Chi" → phiên voice kế tiếp AI dùng Lớp 2 + bộ sách của bé Chi.
5. `flutter analyze` + test xanh.
