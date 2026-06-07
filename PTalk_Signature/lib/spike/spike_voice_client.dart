import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'opus_transcoder.dart';
import 'mic_capture.dart';
import 'pcm_player.dart';

/// Ghép: mic → opus encode → [len][opus] → WebSocket;
/// WebSocket binary → unpack → opus decode → PcmPlayer.
/// Đo độ trễ vòng lặp (gửi frame đầu → nhận audio đầu).
class SpikeVoiceClient {
  static const String wsUrl = 'ws://171.226.10.121:8000/v2/ws';

  final _transcoder = OpusTranscoder();
  final _mic = MicCapture();
  final _player = PcmPlayer();
  WebSocketChannel? _ch;
  StreamSubscription? _micSub;
  StreamSubscription? _wsSub;

  final void Function(String) onLog;
  Stopwatch? _roundTrip;

  SpikeVoiceClient({required this.onLog});

  Future<void> start() async {
    if (!await _mic.ensurePermission()) {
      onLog('❌ Không có quyền micro');
      return;
    }
    await _transcoder.init();
    await _player.init();
    _ch = WebSocketChannel.connect(Uri.parse(wsUrl));
    await _ch!.ready;
    onLog('✅ WS connected: $wsUrl');

    _wsSub = _ch!.stream.listen(_onWsMessage, onError: (e) => onLog('WS error: $e'));

    await _mic.start();
    _roundTrip = Stopwatch()..start();
    var sentFirst = false;
    _micSub = _mic.frames.listen((pcmFrame) {
      final opus = _transcoder.encode(pcmFrame);
      _ch!.sink.add(AudioFrameProtocol.packFrame(opus));
      if (!sentFirst) {
        sentFirst = true;
        onLog('▶️ gửi frame đầu');
      }
    });
  }

  void _onWsMessage(dynamic msg) {
    if (msg is String) {
      onLog('📩 event: $msg');
      return;
    }
    if (msg is! List<int>) return;
    if (_roundTrip != null && _roundTrip!.isRunning) {
      _roundTrip!.stop();
      onLog('⏱️ Round-trip audio đầu tiên: ${_roundTrip!.elapsedMilliseconds} ms');
    }
    try {
      for (final opus in AudioFrameProtocol.unpackFrames(Uint8List.fromList(msg))) {
        _player.feed(_transcoder.decode(opus));
      }
    } on ProtocolException catch (e) {
      onLog('⚠️ unpack lỗi: $e');
    }
  }

  /// Test offline KHÔNG cần server: mic → opus encode → opus decode → loa.
  /// Xác minh 3 plugin native (mic, Opus, PCM playback) chạy được trên thiết bị
  /// (đặc biệt iOS) mà không phụ thuộc mạng tới server.
  Future<void> startLoopback() async {
    if (!await _mic.ensurePermission()) {
      onLog('❌ Không có quyền micro');
      return;
    }
    await _transcoder.init();
    await _player.init();
    onLog('🔁 Loopback (offline) — nói vào mic, bạn sẽ nghe lại sau ~mã hoá Opus');
    await _mic.start();
    var frames = 0;
    _micSub = _mic.frames.listen((pcmFrame) {
      final opus = _transcoder.encode(pcmFrame);
      _player.feed(_transcoder.decode(opus));
      if (++frames % 50 == 0) onLog('… đã xử lý $frames frame (${frames * 20} ms)');
    });
  }

  Future<void> stop() async {
    await _micSub?.cancel();
    await _wsSub?.cancel();
    // dispose() (không chỉ stop()) để giải phóng hẳn AudioRecorder/AVAudioSession,
    // nếu không lần bật thứ 2 sẽ không thu được mic trên iOS.
    await _mic.dispose();
    await _ch?.sink.close();
    await _player.release();
    _transcoder.dispose();
    onLog('⏹️ stopped');
  }
}
