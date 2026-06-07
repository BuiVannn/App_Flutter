# App_Flutter — PTalk Flutter monorepo

Chuyển 3 app Android sang Flutter (Android + iOS). Lần lượt: **PTalk-Signature → KidMentor → P-Connect**.

## Cấu trúc

```
App_Flutter/
├─ packages/ptalk_core/     # package chung (audio protocol, hằng số Opus, … sẽ thêm SSO/network)
└─ PTalk_Signature/         # App 1 (đang làm) — Flutter app, Android + iOS
```

## Trạng thái hiện tại — Phase G0 + G1 (Spike Audio)

Đã xong & build sạch:
- Monorepo + package chung `ptalk_core`.
- `AudioFrameProtocol` (khớp wire-format Android) + 6 unit test.
- App `PTalk_Signature` (Riverpod) với màn **Audio Spike** để kiểm thử pipeline voice:
  mic → Opus (48kHz/20ms) → WebSocket → playback.

## Cách test trên máy local (Mac + Xcode / thiết bị iOS)

```bash
git clone git@github.com:BuiVannn/App_Flutter.git
cd App_Flutter/PTalk_Signature
flutter pub get
flutter run            # chọn iPhone thật (hoặc: mở ios/Runner.xcworkspace bằng Xcode)
```

Trên màn **Audio Spike** có 2 nút:

| Nút | Cần server? | Kiểm tra điều gì |
|---|---|---|
| **Loopback (offline)** | ❌ Không | Mic + Opus encode/decode + phát PCM chạy trên iOS. Nói vào mic → nghe lại giọng đã qua mã hoá Opus. **Test được ngay tại nhà.** |
| **Server (WS)** | ✅ Có | Kết nối `ws://171.226.10.121:8000/v2/ws`, đo round-trip. Cần cùng mạng tới server. |

> Mục tiêu Phase này: xác nhận pipeline audio real-time đạt chất lượng/độ trễ trên iOS thật trước khi build các màn còn lại. Ghi kết quả vào `PTalk_Signature/SPIKE_RESULTS.md`.

## iOS — lưu ý

- Quyền micro đã khai báo (`Info.plist` + macro `PERMISSION_MICROPHONE` trong `Podfile`).
- Deployment target: iOS 13.0.
- Lần đầu mở: `cd ios && pod install` (hoặc `flutter run` tự chạy).
- Cần set Team ký (Signing) trong Xcode để chạy trên máy thật.

## Chạy test logic (không cần thiết bị)

```bash
cd packages/ptalk_core && dart test      # AudioFrameProtocol
cd PTalk_Signature && flutter test        # widget smoke test
```
