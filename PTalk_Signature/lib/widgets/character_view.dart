import 'dart:math';
import 'package:flutter/material.dart';
import '../voice/voice_models.dart';

/// Nhân vật đổi ảnh + chuyển động theo trạng thái — port CharacterAnimator.kt.
class CharacterView extends StatefulWidget {
  const CharacterView({super.key, required this.state, this.size = 180});
  final VoiceState state;
  final double size;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: true);

  String get _asset => switch (widget.state) {
        VoiceState.idle => 'assets/images/char_idle.png',
        VoiceState.recording => 'assets/images/char_listening.png',
        VoiceState.uploading => 'assets/images/char_thinking.png',
        VoiceState.playing => 'assets/images/char_talking.png',
        VoiceState.error => 'assets/images/char_error.png',
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
      builder: (_, child) {
        final v = _c.value; // 0..1 (reversing)
        double scale = 1, dy = 0, rot = 0;
        switch (widget.state) {
          case VoiceState.idle:
            scale = 1 + 0.04 * v;
            dy = -6 * v;
          case VoiceState.recording:
            scale = 1 + 0.12 * v;
            rot = (v - 0.5) * 0.10; // ±~3°
          case VoiceState.uploading:
            scale = 1 + 0.06 * v;
            dy = -8 * v;
          case VoiceState.playing:
            dy = -14 * v;
            scale = 1 + 0.05 * v;
          case VoiceState.error:
            dy = 0;
            rot = sin(v * pi * 4) * 0.08;
        }
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Image.asset(_asset,
          width: widget.size,
          height: widget.size,
          cacheWidth: (widget.size * 3).round()),
    );
  }
}
