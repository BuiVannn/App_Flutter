import 'package:flutter/material.dart';
import 'package:ptalk_core/ptalk_core.dart';

/// Nền gradient xanh chung cho Splash/Login/ModeSelect.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: child,
      );
}

/// Thanh header "kính mờ" với 2 logo hai bên + nhãn ở giữa.
class GlassHeader extends StatelessWidget {
  const GlassHeader({
    super.key,
    required this.centerLabel,
    this.centerSubLabel,
    this.trailing,
  });

  final String centerLabel;
  final String? centerSubLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/logo_ptit.png', height: 36),
          const SizedBox(width: 12),
          Container(width: 1, height: 32, color: AppColors.dividerLine),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (centerSubLabel != null)
                  Text(
                    centerSubLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.dividerLine),
          const SizedBox(width: 12),
          Image.asset('assets/images/logo_cts_main.png', height: 40),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}
