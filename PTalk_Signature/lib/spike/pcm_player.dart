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

  /// pcmFrame: 1920 byte PCM16 LE.
  Future<void> feed(Uint8List pcmFrame) async {
    if (!_ready) return;
    await FlutterPcmSound.feed(PcmArrayInt16(bytes: ByteData.view(pcmFrame.buffer)));
  }

  Future<void> release() async {
    if (_ready) await FlutterPcmSound.release();
    _ready = false;
  }
}
