import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import 'streaming_voice_client.dart';
import 'voice_models.dart';

class VoiceUiState {
  final VoiceState state;
  final String statusText;
  const VoiceUiState(this.state, this.statusText);

  VoiceUiState copyWith({VoiceState? state, String? statusText}) =>
      VoiceUiState(state ?? this.state, statusText ?? this.statusText);
}

class VoiceController extends StateNotifier<VoiceUiState> {
  VoiceController(this._ref)
      : super(VoiceUiState(
            VoiceState.idle, ServerConfig.activeMode.statusIdleText));

  final Ref _ref;
  StreamingVoiceClient? _client;
  Timer? _startAck;
  Timer? _firstAudio;

  String get _idleText => ServerConfig.activeMode.statusIdleText;

  Future<StreamingVoiceClient> _ensureClient() async {
    if (_client != null) return _client!;
    final email = await _ref.read(tokenStoreProvider).email ?? 'guest';
    _client = StreamingVoiceClient(
      deviceId: email,
      onEvent: _onEvent,
      onFirstAudio: _onFirstAudio,
      onError: _onError,
    );
    await _client!.connect();
    return _client!;
  }

  /// Bắt đầu nói (nhấn giữ nút mic).
  Future<void> startTalking() async {
    if (state.state == VoiceState.uploading ||
        state.state == VoiceState.playing) {
      return;
    }
    try {
      final client = await _ensureClient();
      state = const VoiceUiState(VoiceState.recording, 'Đang nghe...');
      final ok = await client.startTalking();
      if (!ok) {
        _toError('Không thể bắt đầu ghi âm');
        return;
      }
      _startAck?.cancel();
      _startAck = Timer(const Duration(seconds: 5), () {
        if (state.state == VoiceState.recording) {
          _toError('Server không phản hồi. Thử lại nhé.');
        }
      });
    } catch (e) {
      _toError('Lỗi kết nối: $e');
    }
  }

  /// Nhả tay → gửi END, chờ xử lý.
  Future<void> stopTalking() async {
    if (state.state != VoiceState.recording) return;
    _startAck?.cancel();
    await _client?.stopTalking();
    state = const VoiceUiState(VoiceState.uploading, 'Đang xử lý...');
    _firstAudio?.cancel();
    _firstAudio = Timer(const Duration(seconds: 30), () {
      if (state.state == VoiceState.uploading) {
        _toError('Server chưa trả lời. Thử lại nhé.');
      }
    });
  }

  /// Huỷ phát (nút X khi đang trả lời).
  Future<void> cancelPlayback() async {
    await _client?.cancelPlayback();
    _resetIdle();
  }

  void _onEvent(StreamingEvent event) {
    switch (event) {
      case Listening():
        _startAck?.cancel();
        state = const VoiceUiState(VoiceState.recording, 'Đang nghe...');
      case Processing():
        state = const VoiceUiState(VoiceState.uploading, 'Đang xử lý...');
      case Thinking():
        state = state.copyWith(statusText: 'Đang suy nghĩ...');
        _firstAudio?.cancel();
        _firstAudio = Timer(const Duration(seconds: 30), () {});
      case Speaking():
        state = const VoiceUiState(VoiceState.playing, 'Đang trả lời...');
      case StreamDone():
        break;
      case IdleEvent():
        _resetIdle();
      case Emotion():
        break;
      case UnknownText(:final text):
        if (text.isNotEmpty) state = state.copyWith(statusText: text);
    }
  }

  void _onFirstAudio() {
    _firstAudio?.cancel();
    state = const VoiceUiState(VoiceState.playing, 'Đang trả lời...');
  }

  void _onError(String message) => _toError(message);

  void _toError(String message) {
    _startAck?.cancel();
    _firstAudio?.cancel();
    state = VoiceUiState(VoiceState.error, message);
    Timer(const Duration(seconds: 2), _resetIdle);
  }

  void _resetIdle() {
    _startAck?.cancel();
    _firstAudio?.cancel();
    state = VoiceUiState(VoiceState.idle, _idleText);
  }

  @override
  void dispose() {
    _startAck?.cancel();
    _firstAudio?.cancel();
    _client?.shutdown();
    super.dispose();
  }
}

final voiceControllerProvider =
    StateNotifierProvider.autoDispose<VoiceController, VoiceUiState>(
        (ref) => VoiceController(ref));
