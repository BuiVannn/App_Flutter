/// Trạng thái UI màn chính — port từ AppState.kt.
enum VoiceState { idle, recording, uploading, playing, error }

/// Sự kiện text từ server — port từ StreamingEvents.kt.
sealed class StreamingEvent {
  const StreamingEvent();

  /// Ánh xạ text server → event.
  static StreamingEvent parse(String text) {
    switch (text.trim()) {
      case 'LISTENING':
        return const Listening();
      case 'PROCESSING':
        return const Processing();
      case 'THINKING':
        return const Thinking();
      case 'SPEAKING':
        return const Speaking();
      case 'STREAM_DONE':
        return const StreamDone();
      case 'IDLE':
        return const IdleEvent();
      default:
        final t = text.trim();
        if (t.length == 2 && int.tryParse(t) != null) return Emotion(t);
        return UnknownText(t);
    }
  }
}

class Listening extends StreamingEvent {
  const Listening();
}

class Processing extends StreamingEvent {
  const Processing();
}

class Thinking extends StreamingEvent {
  const Thinking();
}

class Speaking extends StreamingEvent {
  const Speaking();
}

class StreamDone extends StreamingEvent {
  const StreamDone();
}

class IdleEvent extends StreamingEvent {
  const IdleEvent();
}

class Emotion extends StreamingEvent {
  final String code;
  const Emotion(this.code);
}

class UnknownText extends StreamingEvent {
  final String text;
  const UnknownText(this.text);
}
