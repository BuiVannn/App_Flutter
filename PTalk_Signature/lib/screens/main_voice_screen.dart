import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../voice/voice_controller.dart';
import '../voice/voice_models.dart';
import '../widgets/gradient_background.dart';
import '../widgets/starfield.dart';
import '../widgets/waveform.dart';
import '../widgets/character_view.dart';

/// Màn chính voice real-time — port MainActivity.kt (chế độ streaming WS).
class MainVoiceScreen extends ConsumerWidget {
  const MainVoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ServerConfig.activeMode;
    final ui = ref.watch(voiceControllerProvider);
    final ctrl = ref.read(voiceControllerProvider.notifier);
    final isPlaying = ui.state == VoiceState.playing;

    return GradientBackground(
      child: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: GlassHeader(
                    centerLabel: mode.brandTitle,
                    trailing: IconButton(
                      icon: const Icon(Icons.logout,
                          color: AppColors.textSecondary),
                      tooltip: 'Đăng xuất',
                      onPressed: () async {
                        await ref.read(tokenStoreProvider).clear();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(mode.greetingText,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(mode.subGreetingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 220,
                        child: Waveform(state: ui.state),
                      ),
                      CharacterView(state: ui.state),
                    ],
                  ),
                ),
                _statusChip(ui.statusText, ui.state),
                const SizedBox(height: 16),
                _bottomButton(context, ctrl, ui.state, isPlaying, mode),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, VoiceState state) {
    final color = state == VoiceState.error
        ? AppColors.error
        : AppColors.accentKidDark;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _bottomButton(BuildContext context, VoiceController ctrl,
      VoiceState state, bool isPlaying, AppMode mode) {
    if (isPlaying) {
      return _CircleButton(
        icon: Icons.close,
        color: AppColors.accentElder,
        onTapDown: () {},
        onTapUp: () => ctrl.cancelPlayback(),
        label: 'Chạm để dừng',
      );
    }
    final recording = state == VoiceState.recording;
    return _CircleButton(
      icon: Icons.mic,
      color: recording ? AppColors.accentKidDark : AppColors.accentKid,
      pulsing: recording,
      onTapDown: () => ctrl.startTalking(),
      onTapUp: () => ctrl.stopTalking(),
      label: mode.statusIdleText,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTapDown,
    required this.onTapUp,
    required this.label,
    this.pulsing = false,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final String label;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => onTapDown(),
          onTapUp: (_) => onTapUp(),
          onTapCancel: onTapUp,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: pulsing ? 88 : 80,
            height: pulsing ? 88 : 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: pulsing ? 28 : 16,
                  spreadRadius: pulsing ? 4 : 0,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
