import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:ptalk_core/ptalk_core.dart';

/// Phát PCM16 mono 48kHz đẩy theo từng frame.
class PcmPlayer {
  bool _ready = false;

  Future<void> init() async {
    await FlutterPcmSound.setup(
      sampleRate: OpusAudioFormat.sampleRate,
      channelCount: OpusAudioFormat.channelCount,
    );
    FlutterPcmSound.setFeedThreshold(OpusAudioFormat.samplesPerFrame * 4);
    _ready = true;
  }

  /// pcmFrame: PCM16 LE. Lưu ý pcmFrame có thể là VIEW chia sẻ buffer của cả
  /// gói WS — phải copy đúng đoạn của khung (offset+length), nếu không sẽ phát
  /// nhầm cả gói → âm thanh rè/lặp.
  Future<void> feed(Uint8List pcmFrame) async {
    if (!_ready) return;
    final frame = Uint8List.fromList(pcmFrame); // copy contiguous, đúng độ dài
    await FlutterPcmSound.feed(
        PcmArrayInt16(bytes: ByteData.view(frame.buffer)));
  }

  Future<void> release() async {
    if (_ready) await FlutterPcmSound.release();
    _ready = false;
  }
}
