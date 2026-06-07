import 'dart:math';
import 'package:flutter/material.dart';

/// Nền sao lấp lánh trôi nhẹ — port từ StarFieldView.kt (CustomPainter).
class Starfield extends StatefulWidget {
  const Starfield({super.key, this.starCount = 45});
  final int starCount;

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _Star {
  double x, y, size, baseAlpha, speedX, speedY, twinkleSpeed, phase;
  _Star(this.x, this.y, this.size, this.baseAlpha, this.speedX, this.speedY,
      this.twinkleSpeed, this.phase);
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))
        ..repeat();
  final _rng = Random(42);
  late final List<_Star> _stars;

  static const _colors = [
    Color(0xFF5EC99A),
    Color(0xFF7DD9B0),
    Color(0xFFA8E8CC),
    Color(0xFF4DC990),
    Color(0xFF6DCFAA),
    Color(0xFF8FE0BF),
    Color(0xFF3DAB7A),
  ];

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.starCount, (_) {
      return _Star(
        _rng.nextDouble(),
        _rng.nextDouble(),
        6 + _rng.nextDouble() * 12,
        80 + _rng.nextDouble() * 140,
        (_rng.nextDouble() - 0.5) * 0.0006,
        (0.2 + _rng.nextDouble() * 0.5) * 0.0006,
        0.025 + _rng.nextDouble() * 0.05,
        _rng.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _StarfieldPainter(_stars, _c.value, _colors),
        size: Size.infinite,
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.stars, this.t, this.colors);
  final List<_Star> stars;
  final double t; // 0..1
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = t * 960; // ~16s * 60fps
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      var px = (s.x + s.speedX * frame) % 1.0;
      var py = (s.y + s.speedY * frame) % 1.0;
      if (px < 0) px += 1.0;
      if (py < 0) py += 1.0;
      final twinkle = (sin(s.phase + frame * s.twinkleSpeed) + 1) / 2;
      final alpha = (s.baseAlpha * (0.4 + 0.6 * twinkle)).clamp(0, 255).toInt();
      final paint = Paint()..color = colors[i % colors.length].withAlpha(alpha);
      _drawStar(canvas, Offset(px * size.width, py * size.height), s.size, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double outer, Paint paint) {
    final inner = outer * 0.4;
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final r = k.isEven ? outer : inner;
      final a = pi / 2 * (k / 2);
      final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.t != t;
}
