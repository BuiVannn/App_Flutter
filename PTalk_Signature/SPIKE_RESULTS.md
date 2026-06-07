# Kết quả Spike Audio (G1) — PTalk-Signature Flutter

> Điền bảng dưới sau khi chạy `flutter run` trên thiết bị thật (xem Task 9 trong plan).

## Bảng đo

| Nền tảng | Thiết bị | Opus nạp được? | Thu mic (~50 frame/s)? | Round-trip audio đầu (ms) | Chất lượng (rõ/méo/đứt) | Ổn định ≥2 phút? |
|---|---|---|---|---|---|---|
| Android |  |  |  |  |  |  |
| iOS |  |  |  |  |  |  |

## Tiêu chí cổng quyết định

ĐẠT (đi tiếp G2–G6 với pure-Flutter audio) khi:
- [ ] Round-trip ổn định, độ trễ tương đương cảm nhận so với bản Android.
- [ ] Âm thanh rõ, không đứt/méo ở cả Android lẫn iOS.
- [ ] Không crash sau ≥2 phút nói liên tục.

## Quyết định

- [ ] **ĐẠT** → viết plan G2–G6, dùng pipeline audio thuần Flutter ở đây.
- [ ] **KHÔNG ĐẠT** → viết platform channel (Kotlin `AudioRecord`/`MediaCodec` + Swift `AVAudioEngine`/`AudioToolbox`) cho mic+opus, giữ nguyên interface Dart `MicCapture`/`OpusTranscoder`.

Ghi chú quyết định: …
