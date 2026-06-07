import 'package:flutter/material.dart';
import 'package:ptalk_core/ptalk_core.dart';

/// Nền gradient theo chế độ (Kid xanh / Elder cam) và theme sáng/tối.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final elder = ServerConfig.activeMode == AppMode.elderCare;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.screenGradientFor(elder: elder, dark: dark),
      ),
      child: child,
    );
  }
}

/// Thanh header "kính mờ" với 2 logo hai bên + nhãn ở giữa.
class GlassHeader extends StatelessWidget {
  const GlassHeader({
    super.key,
    required this.centerLabel,
    this.centerSubLabel,
    this.leading,
    this.trailing,
  });

  final String centerLabel;
  final String? centerSubLabel;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textOn(dark);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.10 : 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.18 : 0.6)),
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else
            Image.asset('assets/images/logo_ptit.png', height: 36),
          const SizedBox(width: 10),
          Container(width: 1, height: 30, color: AppColors.dividerLine),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    color: textColor,
                  ),
                ),
                if (centerSubLabel != null)
                  Text(
                    centerSubLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.dividerLine),
          const SizedBox(width: 10),
          Image.asset('assets/images/logo_cts_main.png', height: 38),
          ?trailing,
        ],
      ),
    );
  }
}
