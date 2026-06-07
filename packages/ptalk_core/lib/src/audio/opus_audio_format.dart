/// Hằng số định dạng Opus — PHẢI khớp server & bản Android.
class OpusAudioFormat {
  static const int sampleRate = 48000;
  static const int channelCount = 1;
  static const int frameDurationMs = 20;
  static const int samplesPerFrame = sampleRate ~/ 1000 * frameDurationMs; // 960
  static const int pcmBytesPerSample = 2;
  static const int pcmFrameBytes = samplesPerFrame * pcmBytesPerSample; // 1920
}
