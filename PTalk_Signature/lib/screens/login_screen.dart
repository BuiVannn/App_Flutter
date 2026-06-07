import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../widgets/gradient_background.dart';

/// Màn đăng nhập — SSO Authentik + vào xem thử (guest). Theo bản Android:
/// 1 lần đăng nhập mở khoá cả Kid/Elder; phải đồng ý điều khoản mới bật nút.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _agreed = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _login() async {
    final ok = await ref.read(loginControllerProvider.notifier).loginWithSso();
    if (ok && mounted) context.go('/mode-select');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final busy = state is LoginInProgress;
    final error = state is LoginFailure ? state.message : null;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                const GlassHeader(centerLabel: 'PTALK'),
                const SizedBox(height: 32),
                // Hero mascot trong halo
                Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset('assets/images/char_idle.png'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CHÀO MỪNG\nBẠN TRỞ LẠI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục sử dụng PTalk',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                _formCard(busy, error),
                const SizedBox(height: 20),
                const Text(
                  '© 2025 Lab CTS · Học viện Bưu chính Viễn thông PTIT\nMọi quyền được bảo lưu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(bool busy, String? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreed,
                onChanged: busy ? null : (v) => setState(() => _agreed = v ?? false),
                activeColor: AppColors.textPrimary,
              ),
              Expanded(child: _consentText()),
            ],
          ),
          if (!_agreed)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vui lòng đồng ý để tiếp tục',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          const SizedBox(height: 12),
          // Nút đăng nhập SSO (pill đen)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: (_agreed && !busy) ? _login : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.buttonDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.vpn_key, size: 18),
              label: Text(busy ? 'ĐANG ĐĂNG NHẬP…' : 'ĐĂNG NHẬP VỚI SSO'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.dividerLine)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('hoặc',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
              const Expanded(child: Divider(color: AppColors.dividerLine)),
            ],
          ),
          const SizedBox(height: 14),
          // Nút vào xem thử (outlined)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: (_agreed && !busy)
                  ? () => context.go('/mode-select')
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              child: const Text('VÀO XEM THỬ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consentText() {
    const linkStyle = TextStyle(
      color: AppColors.linkBlue,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12.5, color: AppColors.textBody, height: 1.3),
        children: [
          const TextSpan(text: 'Tôi đồng ý với '),
          TextSpan(
            text: 'Chính sách bảo mật',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl('https://dashboard.ctslab.net/privacy'),
          ),
          const TextSpan(text: ' và '),
          TextSpan(
            text: 'Điều khoản',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl('https://dashboard.ctslab.net/terms'),
          ),
        ],
      ),
    );
  }
}
