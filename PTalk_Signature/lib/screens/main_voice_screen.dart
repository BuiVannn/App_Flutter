import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../settings/settings_providers.dart';
import '../voice/voice_controller.dart';
import '../voice/voice_models.dart';
import '../widgets/gradient_background.dart';
import '../widgets/starfield.dart';
import '../widgets/waveform.dart';
import '../widgets/character_view.dart';

/// Màn chính voice — port MainActivity.kt (layout + z-order gốc).
class MainVoiceScreen extends ConsumerWidget {
  const MainVoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ServerConfig.activeMode;
    final elder = mode == AppMode.elderCare;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ui = ref.watch(voiceControllerProvider);
    final ctrl = ref.read(voiceControllerProvider.notifier);

    final accent = elder ? AppColors.accentElder : AppColors.accentKid;
    final accentDark =
        elder ? AppColors.accentElderDark : AppColors.accentKidDark;
    final greetingColor = elder ? AppColors.greetingElder : AppColors.greetingKid;
    final subColor = elder ? AppColors.subGreetingElder : accentDark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(child: RepaintBoundary(child: Starfield())),
            SafeArea(
              child: Column(
                children: [
                  // ── Brand bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GlassHeader(centerLabel: 'P-Talk Signature'),
                  ),
                  // ── Back (về chọn chế độ) + Settings ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.textOn(dark),
                          tooltip: 'Chọn chế độ',
                          onPressed: () => context.go('/mode-select'),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: AppColors.textOn(dark),
                          tooltip: 'Cài đặt',
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                  // ── Greeting card (frosted) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 84),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: dark ? 0.10 : 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: dark ? 0.16 : 0.6)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mode.greetingText,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: greetingColor)),
                          const SizedBox(height: 4),
                          Text(mode.subGreetingText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: subColor)),
                        ],
                      ),
                    ),
                  ),
                  // ── Waveform (sau) + Character (trước) ──
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final charSize =
                            (c.maxWidth * 0.82).clamp(220.0, 360.0);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 260,
                              child: RepaintBoundary(
                                  child: Waveform(state: ui.state)),
                            ),
                            CharacterView(state: ui.state, size: charSize),
                          ],
                        );
                      },
                    ),
                  ),
                  // ── Status ──
                  _statusChip(ui.statusText, ui.state, accentDark),
                  const SizedBox(height: 14),
                  // ── Bottom controls ──
                  _bottomControls(context, ref, ctrl, ui.state, elder, accent,
                      accentDark),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, VoiceState state, Color accentDark) {
    final color = state == VoiceState.error ? AppColors.error : accentDark;
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

  Widget _bottomControls(
      BuildContext context,
      WidgetRef ref,
      VoiceController ctrl,
      VoiceState state,
      bool elder,
      Color accent,
      Color accentDark) {
    final isPlaying = state == VoiceState.playing;
    final mic = isPlaying
        ? _circle(
            icon: Icons.close,
            color: AppColors.accentElder,
            size: 72,
            onTapDown: () {},
            onTapUp: () => ctrl.cancelPlayback(),
          )
        : _circle(
            icon: Icons.mic,
            color: state == VoiceState.recording ? accentDark : accent,
            size: 72,
            pulsing: state == VoiceState.recording,
            onTapDown: () => ctrl.startTalking(),
            onTapUp: () => ctrl.stopTalking(),
          );

    if (!elder) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mic,
          const SizedBox(height: 10),
          Text(ServerConfig.activeMode.statusIdleText,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
    }

    // Elder: [quét thuốc] [mic] [gọi khẩn cấp] — cùng cỡ, cùng hàng.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circle(
          icon: Icons.medication_outlined,
          color: AppColors.accentElder,
          size: 72,
          onTapDown: () {},
          onTapUp: () => context.push('/scan'),
        ),
        const SizedBox(width: 28),
        mic,
        const SizedBox(width: 28),
        _circle(
          icon: Icons.phone,
          color: const Color(0xFFD32F2F),
          size: 72,
          onTapDown: () {},
          onTapUp: () => _callEmergency(ref),
        ),
      ],
    );
  }

  Future<void> _callEmergency(WidgetRef ref) async {
    final store = await ref.read(settingsStoreProvider.future);
    final uri = Uri(scheme: 'tel', path: store.emergencyNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _circle({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    bool pulsing = false,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: pulsing ? size + 8 : size,
        height: pulsing ? size + 8 : size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: pulsing ? 26 : 14,
              spreadRadius: pulsing ? 4 : 0,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}
