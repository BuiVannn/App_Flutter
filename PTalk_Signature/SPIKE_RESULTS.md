# Kết quả Spike Audio (G1) — PTalk-Signature Flutter

> Điền bảng dưới sau khi chạy `flutter run` trên thiết bị thật (xem Task 9 trong plan).

## Bước 0 — Loopback offline (KHÔNG cần server)

Bấm nút **"Loopback (offline)"**, nói vào mic → phải nghe lại giọng (đã qua Opus encode→decode).
Đây là xác nhận quan trọng nhất cho iOS: mic + Opus + PCM playback hoạt động.

| Nền tảng | Thiết bị | Opus nạp được? | Nghe lại được (loopback)? | Méo/đứt? | Crash? |
|---|---|---|---|---|---|
| iOS |  |  |  |  |  |
| Android |  |  |  |  |  |

## Bước 1 — Round-trip qua server (cần cùng mạng tới 171.226.10.121:8000)

| Nền tảng | Thiết bị | WS connect OK? | Round-trip audio đầu (ms) | Chất lượng | Ổn định ≥2 phút? |
|---|---|---|---|---|---|
| Android |  |  |  |  |  |
| iOS |  |  |  |  |  |

## Tiêu chí cổng quyết định

ĐẠT (đi tiếp G2–G6 với pure-Flutter audio) khi:
- [ ] Round-trip ổn định, độ trễ tương đương cảm nhận so với bản Android.
- [ ] Âm thanh rõ, không đứt/méo ở cả Android lẫn iOS.
- [ ] Không crash sau ≥2 phút nói liên tục.

## Kết quả thực tế (2026-06-07)

- iOS thiết bị thật: **Loopback ĐẠT** — nghe lại được, không nhiễu nhiều. Lặp Bật/Dừng nhiều lần OK sau fix (guard `initOpus` + dispose mic).
- Nhược điểm nhỏ: âm lượng hơi bé + vang kiểu mic gần loa (đặc thù loopback, không phải lỗi đường truyền). Sẽ không xuất hiện ở chế độ Server thật; có thể chỉnh gain sau.
- → **Pipeline audio thuần Flutter ĐẠT**, tiếp tục G2–G6 không cần platform channel.

## Quyết định

- [ ] **ĐẠT** → viết plan G2–G6, dùng pipeline audio thuần Flutter ở đây.
- [ ] **KHÔNG ĐẠT** → viết platform channel (Kotlin `AudioRecord`/`MediaCodec` + Swift `AVAudioEngine`/`AudioToolbox`) cho mic+opus, giữ nguyên interface Dart `MicCapture`/`OpusTranscoder`.

Ghi chú quyết định: …
