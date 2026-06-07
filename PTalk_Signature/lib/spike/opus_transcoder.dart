import 'dart:typed_data';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:ptalk_core/ptalk_core.dart';

/// Encode/decode 1 frame 20ms PCM16 mono 48kHz ⇄ Opus.
class OpusTranscoder {
  late final SimpleOpusEncoder _encoder;
  late final SimpleOpusDecoder _decoder;
  bool _ready = false;

  Future<void> init() async {
    initOpus(await opus_flutter.load());
    _encoder = SimpleOpusEncoder(
      sampleRate: OpusAudioFormat.sampleRate,
      channels: OpusAudioFormat.channelCount,
      application: Application.voip,
    );
    _decoder = SimpleOpusDecoder(
      sampleRate: OpusAudioFormat.sampleRate,
      channels: OpusAudioFormat.channelCount,
    );
    _ready = true;
  }

  /// pcmFrame: 1920 bytes (960 samples Int16 LE). Trả về opus payload.
  Uint8List encode(Uint8List pcmFrame) {
    assert(_ready);
    final pcm16 = Int16List.view(
        pcmFrame.buffer, pcmFrame.offsetInBytes, OpusAudioFormat.samplesPerFrame);
    return _encoder.encode(input: pcm16);
  }

  /// opusFrame -> PCM16 bytes (1920).
  Uint8List decode(Uint8List opusFrame) {
    assert(_ready);
    final pcm16 = _decoder.decode(input: opusFrame);
    return Uint8List.view(pcm16.buffer, pcm16.offsetInBytes, pcm16.lengthInBytes);
  }

  void dispose() {
    if (!_ready) return;
    _encoder.destroy();
    _decoder.destroy();
  }
}
