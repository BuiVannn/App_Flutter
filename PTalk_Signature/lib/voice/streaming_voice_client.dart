import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../spike/opus_transcoder.dart';
import '../spike/mic_capture.dart';
import '../spike/pcm_player.dart';
import 'voice_models.dart';

/// Client voice real-time qua WebSocket — port từ StreamingVoiceClient.kt.
///
/// Luồng: connect → handshake → START → (LISTENING) → stream opus →
/// END → PROCESSING → [THINKING] → SPEAKING + audio → STREAM_DONE → IDLE.
class StreamingVoiceClient {
  StreamingVoiceClient({
    required this.deviceId,
    required this.onEvent,
    required this.onFirstAudio,
    required this.onError,
  });

  /// Email/định danh thiết bị gửi trong handshake.
  final String deviceId;
  final void Function(StreamingEvent) onEvent;
  final void Function() onFirstAudio;
  final void Function(String) onError;

  final _transcoder = OpusTranscoder();
  final _mic = MicCapture();
  final _player = PcmPlayer();

  WebSocketChannel? _ch;
  StreamSubscription? _wsSub;
  StreamSubscription? _micSub;

  bool _ready = false;
  bool _serverListening = false;
  bool _receivedFirstAudio = false;
  bool _accepting = false; // có nhận & phát audio đến không (tắt khi huỷ/xong)
  final _outgoing = <Uint8List>[]; // opus frame đã pack, chờ LISTENING

  /// Khởi tạo codec/player + mở WS + handshake. Gọi 1 lần.
  Future<void> connect() async {
    if (_ready) return;
    await _transcoder.init();
    await _player.init();
    _ch = WebSocketChannel.connect(Uri.parse(ServerConfig.wsUrl));
    await _ch!.ready;
    _wsSub = _ch!.stream.listen(_onMessage,
        onError: (e) => onError('WS lỗi: $e'),
        onDone: () => _ready = false);
    _ch!.sink.add(jsonEncode(
        {'device_id': deviceId, 'firmware_version': '2.0.0'}));
    _ready = true;
  }

  /// Bắt đầu nói: gửi START, thu mic, đẩy opus (queue tới khi LISTENING).
  Future<bool> startTalking() async {
    if (!await _mic.ensurePermission()) {
      onError('Không có quyền micro');
      return false;
    }
    if (!_ready) await connect();
    _serverListening = false;
    _receivedFirstAudio = false;
    _accepting = true;
    _outgoing.clear();
    // START_PCM_OUT: client gửi Opus lên, server gửi PCM thô về (khớp bản gốc,
    // tránh lỗi opus-decode). isPcmEncoding=false ⇒ "START_PCM_OUT".
    _ch!.sink.add('START_PCM_OUT');
    await _mic.start();
    _micSub = _mic.frames.listen((pcmFrame) {
      final packed = AudioFrameProtocol.packFrame(_transcoder.encode(pcmFrame));
      if (_serverListening) {
        _ch!.sink.add(packed);
      } else {
        _outgoing.add(packed);
      }
    });
    return true;
  }

  /// Nhả tay: dừng mic, gửi END để server xử lý.
  Future<void> stopTalking() async {
    await _micSub?.cancel();
    _micSub = null;
    await _mic.stop();
    if (_ready) _ch!.sink.add('END');
  }

  /// Huỷ/dừng phát NGAY (nút X) — cắt audio, xả buffer, bỏ audio đến muộn.
  Future<void> stopPlayback() async {
    _accepting = false;
    _receivedFirstAudio = false;
    await _player.release(); // dừng + xoá buffer
    await _player.init(); // sẵn sàng cho lần sau
  }

  Future<void> cancelPlayback() => stopPlayback();

  void _onMessage(dynamic msg) {
    if (msg is String) {
      _onText(msg);
      return;
    }
    if (!_accepting) return; // đã huỷ/kết thúc → bỏ audio đến muộn
    final bytes = msg is Uint8List
        ? msg
        : (msg is List<int> ? Uint8List.fromList(msg) : null);
    if (bytes == null) return;
    if (!_receivedFirstAudio) {
      _receivedFirstAudio = true;
      onFirstAudio();
    }
    try {
      // START_PCM_OUT: mỗi khung đã là PCM16 thô — phát thẳng, KHÔNG opus-decode.
      for (final pcm in AudioFrameProtocol.unpackFrames(bytes)) {
        _player.feed(pcm);
      }
    } on ProtocolException catch (e) {
      onError('Giải mã audio lỗi: $e');
    }
  }

  void _onText(String text) {
    final event = StreamingEvent.parse(text);
    if (event is Listening) {
      _serverListening = true;
      for (final f in _outgoing) {
        _ch?.sink.add(f);
      }
      _outgoing.clear();
    }
    // IDLE = server báo kết thúc phiên → ngừng nhận audio mới (buffer đã có sẽ
    // tự phát hết). Tránh phát kéo dài sau khi model nói xong.
    if (event is IdleEvent) _accepting = false;
    onEvent(event);
  }

  Future<void> shutdown() async {
    await _micSub?.cancel();
    await _wsSub?.cancel();
    await _mic.dispose();
    await _ch?.sink.close();
    await _player.release();
    _transcoder.dispose();
    _ready = false;
  }
}
