import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../widgets/gradient_background.dart';

/// Splash: logo fade+scale (overshoot) → lật 3D (rotationY 360°) → tiêu đề
/// fade/slide → chờ → điều hướng. Port SplashActivity.kt.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();

  // Các pha theo timeline gốc (đã chuẩn hoá 0..1 trên tổng 2600ms).
  late final Animation<double> _logoIn = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.08, 0.27, curve: Curves.easeOut)); // fade+scale
  late final Animation<double> _flip = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.27, 0.58, curve: Curves.easeInOut)); // lật 3D
  late final Animation<double> _titlesIn = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.58, 0.80, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;
    final loggedIn = await ref.read(tokenStoreProvider).isLoggedIn();
    if (!mounted) return;
    context.go(loggedIn ? '/mode-select' : '/login');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.04),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    // Overshoot scale 0.3→1.06→1.0
                    final s = 0.3 + 0.76 * Curves.easeOutBack.transform(_logoIn.value);
                    final flipAngle = _flip.value * 2 * math.pi;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _logoIn.value.clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateY(flipAngle)
                              ..scaleByDouble(s, s, 1, 1),
                            child: _logoCard(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _slideFade(
                          _titlesIn,
                          const Text(
                            'Đồng hành cùng trẻ em & người cao tuổi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _slideFade(
                          _titlesIn,
                          Image.asset('assets/images/logo_cts_flashscreen.png',
                              height: 84, cacheWidth: 360),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 160, height: 1, color: AppColors.dividerLine),
                      const SizedBox(height: 12),
                      const Text(
                        'Học viện Công nghệ Bưu chính Viễn thông',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoCard() => Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Image.asset('assets/images/logo_ptalk_signature.png',
            cacheWidth: 480),
      );

  Widget _slideFade(Animation<double> a, Widget child) {
    return AnimatedBuilder(
      animation: a,
      builder: (_, _) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - a.value)), child: child),
      ),
    );
  }
}
