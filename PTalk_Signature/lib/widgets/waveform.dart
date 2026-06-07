import 'dart:math';
import 'package:flutter/material.dart';
import '../voice/voice_models.dart';

/// Sóng âm đối xứng quanh trục giữa, thuôn 2 đầu (không có đáy vuông), nhiều lớp
/// — biên độ/tốc độ đổi theo trạng thái. Cảm hứng từ WaveformView.kt.
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
  double _amp = 0.18;

  double get _targetAmp => switch (widget.state) {
        VoiceState.idle => 0.16,
        VoiceState.recording => 0.34,
        VoiceState.uploading => 0.24,
        VoiceState.playing => 0.46,
        VoiceState.error => 0.08,
      };

  double get _speed => switch (widget.state) {
        VoiceState.idle => 0.5,
        VoiceState.recording => 1.4,
        VoiceState.uploading => 0.9,
        VoiceState.playing => 2.0,
        VoiceState.error => 0.3,
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
        _amp += (_targetAmp - _amp) * 0.06; // mượt tới biên độ mục tiêu
        return CustomPaint(
          painter: _WavePainter(_c.value, _amp, _speed),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Layer {
  final Color color;
  final double freq, speedMul, ampMul, phaseShift;
  final int alpha;
  const _Layer(this.color, this.freq, this.speedMul, this.ampMul,
      this.phaseShift, this.alpha);
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t, this.amp, this.speed);
  final double t, amp, speed;

  static const _layers = [
    _Layer(Color(0xFF4DC990), 2.0, 1.0, 1.00, 0.0, 70),
    _Layer(Color(0xFF7DD9B0), 3.0, 1.6, 0.65, 1.2, 55),
    _Layer(Color(0xFFA8E8CC), 1.4, 0.7, 0.80, 2.4, 40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final phase = t * 2 * pi * speed;
    for (final l in _layers) {
      final maxA = amp * size.height * l.ampMul;
      final path = Path();
      // Biên trên (đi từ trái sang phải)
      for (double x = 0; x <= size.width; x += 3) {
        final n = x / size.width;
        final env = sin(pi * n); // 0 ở 2 đầu, 1 ở giữa → thuôn đầu
        final w = maxA *
            env *
            (0.6 * sin(n * 2 * pi * l.freq + phase * l.speedMul + l.phaseShift) +
                0.4 * sin(n * 2 * pi * l.freq * 1.7 - phase * l.speedMul));
        final y = cy - w;
        x == 0 ? path.moveTo(0, y) : path.lineTo(x, y);
      }
      // Biên dưới (đối xứng, đi ngược về trái)
      for (double x = size.width; x >= 0; x -= 3) {
        final n = x / size.width;
        final env = sin(pi * n);
        final w = maxA *
            env *
            (0.6 * sin(n * 2 * pi * l.freq + phase * l.speedMul + l.phaseShift) +
                0.4 * sin(n * 2 * pi * l.freq * 1.7 - phase * l.speedMul));
        path.lineTo(x, cy + w);
      }
      path.close();
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = l.color.withAlpha(l.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.amp != amp;
}
