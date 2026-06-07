import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ptalk_core/ptalk_core.dart';

/// Phát ra các frame PCM16 mono 48kHz, mỗi frame đúng 1920 byte (20ms).
class MicCapture {
  final _recorder = AudioRecorder();
  final _frameController = StreamController<Uint8List>();
  StreamSubscription<Uint8List>? _sub;
  final _buffer = BytesBuilder();

  Stream<Uint8List> get frames => _frameController.stream;

  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: OpusAudioFormat.sampleRate,
      numChannels: OpusAudioFormat.channelCount,
    ));
    _sub = stream.listen(_onChunk);
  }

  void _onChunk(Uint8List chunk) {
    _buffer.add(chunk);
    while (_buffer.length >= OpusAudioFormat.pcmFrameBytes) {
      final all = _buffer.toBytes();
      final frame = Uint8List.sublistView(all, 0, OpusAudioFormat.pcmFrameBytes);
      _frameController.add(Uint8List.fromList(frame));
      _buffer.clear();
      _buffer.add(Uint8List.sublistView(all, OpusAudioFormat.pcmFrameBytes));
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await _recorder.stop();
    _buffer.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _frameController.close();
  }
}
