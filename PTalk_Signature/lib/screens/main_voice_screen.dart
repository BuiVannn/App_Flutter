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
    // Khi đang phát → nút X (tap để dừng). Còn lại → nút mic GIỮ-ĐỂ-NÓI.
    final mic = isPlaying
        ? _tapCircle(
            icon: Icons.close,
            color: AppColors.accentElder,
            onTap: () => ctrl.cancelPlayback(),
          )
        : _holdCircle(
            color: state == VoiceState.recording ? accentDark : accent,
            pulsing: state == VoiceState.recording,
            onHoldStart: ctrl.startTalking,
            onHoldEnd: ctrl.stopTalking,
          );

    if (!elder) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mic,
          const SizedBox(height: 10),
          Text(
              isPlaying
                  ? 'Chạm để dừng'
                  : 'Giữ nút để nói · nhả ra để gửi',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
    }

    // Elder: [quét thuốc] [mic] [gọi khẩn cấp] — cùng cỡ, cùng hàng.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tapCircle(
          icon: Icons.medication_outlined,
          color: AppColors.accentElder,
          onTap: () => context.push('/scan'),
        ),
        const SizedBox(width: 28),
        mic,
        const SizedBox(width: 28),
        _tapCircle(
          icon: Icons.phone,
          color: const Color(0xFFD32F2F),
          onTap: () => _callEmergency(ref),
        ),
      ],
    );
  }

  Future<void> _callEmergency(WidgetRef ref) async {
    final store = await ref.read(settingsStoreProvider.future);
    final uri = Uri(scheme: 'tel', path: store.emergencyNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  /// Nút bấm thường (tap) — dùng cho X / quét thuốc / gọi khẩn cấp.
  Widget _tapCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: _circleVisual(icon: icon, color: color, size: 72),
      );

  /// Nút GIỮ-ĐỂ-NÓI — dùng Listener (pointer) cho chắc chắn, không bị
  /// gesture tap huỷ khi tay hơi di chuyển. Nhấn xuống = bắt đầu, nhả = gửi.
  Widget _holdCircle({
    required Color color,
    required bool pulsing,
    required VoidCallback onHoldStart,
    required VoidCallback onHoldEnd,
  }) {
    return Listener(
      onPointerDown: (_) => onHoldStart(),
      onPointerUp: (_) => onHoldEnd(),
      onPointerCancel: (_) => onHoldEnd(),
      child: _circleVisual(
          icon: Icons.mic, color: color, size: 72, pulsing: pulsing),
    );
  }

  Widget _circleVisual({
    required IconData icon,
    required Color color,
    required double size,
    bool pulsing = false,
  }) {
    return AnimatedContainer(
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
    );
  }
}
