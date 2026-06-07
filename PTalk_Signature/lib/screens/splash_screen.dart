import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../widgets/gradient_background.dart';

/// Màn chờ: hiện logo + fade-in, sau ~2.2s điều hướng theo trạng thái đăng nhập.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
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
          child: FadeTransition(
            opacity: _c,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Image.asset('assets/images/logo_ptalk_signature.png',
                      cacheWidth: 600),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đồng hành cùng trẻ em & người cao tuổi',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const Spacer(),
                Image.asset('assets/images/logo_cts_flashscreen.png', height: 64),
                const SizedBox(height: 12),
                Container(
                  width: 160,
                  height: 1,
                  color: AppColors.dividerLine,
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Học viện Công nghệ Bưu chính Viễn thông',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
