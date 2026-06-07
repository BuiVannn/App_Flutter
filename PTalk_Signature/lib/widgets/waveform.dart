import 'dart:math';
import 'package:flutter/material.dart';
import '../voice/voice_models.dart';

/// Sóng 3 lớp gradient, biên độ/tốc độ đổi theo trạng thái — port WaveformView.kt.
class Waveform extends StatefulWidget {
  const Waveform({super.key, required this.state});
  final VoiceState state;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();
  double _amp = 70;

  double get _targetAmp => switch (widget.state) {
        VoiceState.idle => 70,
        VoiceState.recording => 120,
        VoiceState.uploading => 90,
        VoiceState.playing => 160,
        VoiceState.error => 30,
      };

  double get _speed => switch (widget.state) {
        VoiceState.idle => 0.3,
        VoiceState.recording => 0.7,
        VoiceState.uploading => 0.45,
        VoiceState.playing => 1.0,
        VoiceState.error => 0.15,
      };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        _amp += (_targetAmp - _amp) * 0.06; // smooth tới biên độ mục tiêu
        return CustomPaint(
          painter: _WavePainter(_c.value, _amp, _speed),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Layer {
  final Color top, bottom;
  final double freq, speedMul, baseline;
  final int alpha;
  const _Layer(
      this.top, this.bottom, this.freq, this.speedMul, this.baseline, this.alpha);
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t, this.amp, this.speed);
  final double t, amp, speed;

  static const _layers = [
    _Layer(Color(0xFF5EC99A), Color(0xFF3DAB7A), 1.0, 0.6, 0.55, 90),
    _Layer(Color(0xFF7DD9B0), Color(0xFF4DC990), 1.8, 1.0, 0.65, 70),
    _Layer(Color(0xFFA8E8CC), Color(0xFF6DCFAA), 0.7, 0.4, 0.48, 55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * pi;
    for (final l in _layers) {
      final baseY = size.height * l.baseline;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final norm = x / size.width;
        final y = baseY -
            amp *
                0.5 *
                sin(norm * 2 * pi * l.freq + phase * l.speedMul * speed * 3);
        x == 0 ? path.lineTo(0, y) : path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [l.top.withAlpha(l.alpha), l.bottom.withAlpha(l.alpha ~/ 2)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.amp != amp;
}
