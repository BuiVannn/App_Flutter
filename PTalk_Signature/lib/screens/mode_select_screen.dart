import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';

/// Chọn chế độ Kid Mentor / Elder Care. Theo bản Android: hiện sau Login.
class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  void _select(BuildContext context, AppMode mode) {
    ServerConfig.activeMode = mode;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassHeader(
                  centerLabel: 'PTALK AI',
                  centerSubLabel: 'Lab CTS · PTIT',
                  trailing: IconButton(
                    icon: const Icon(Icons.settings,
                        color: AppColors.textSecondary),
                    onPressed: () => context.push('/settings'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CHỌN CHẾ ĐỘ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mỗi chế độ là một trợ lý riêng — chọn để bắt đầu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ModeCard(
                          badge: 'TRẺ EM · 4–12 TUỔI',
                          icon: 'assets/images/mode_logo_kid.png',
                          title: 'KID MENTOR',
                          subtitle: 'Trợ lý học tập cho trẻ em',
                          features: const [
                            'Học qua trò chuyện vui nhộn',
                            'Kể chuyện, câu đố & khám phá',
                            'An toàn, thân thiện với trẻ',
                          ],
                          cta: 'Bắt đầu học',
                          accent: AppColors.accentKid,
                          accentDark: AppColors.accentKidDark,
                          cardBg: AppColors.kidCardBg,
                          badgeBg: AppColors.kidBadgeBg,
                          halo: AppColors.kidHalo,
                          onTap: () => _select(context, AppMode.kidMentor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModeCard(
                          badge: 'NGƯỜI CAO TUỔI',
                          icon: 'assets/images/mode_logo_elder.png',
                          title: 'ELDER CARE',
                          subtitle: 'Trợ lý sức khoẻ cho người cao tuổi',
                          features: const [
                            'Nhắc lịch uống thuốc đúng giờ',
                            'Quét & đọc thông tin thuốc',
                            'Gọi khẩn cấp chỉ một chạm',
                          ],
                          cta: 'Bắt đầu',
                          accent: AppColors.accentElder,
                          accentDark: AppColors.accentElderDark,
                          cardBg: AppColors.elderCardBg,
                          badgeBg: AppColors.elderBadgeBg,
                          halo: AppColors.elderHalo,
                          onTap: () => _select(context, AppMode.elderCare),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn có thể đổi chế độ bất cứ lúc nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                const Text(
                  '© 2025 Lab CTS · Học viện Bưu chính Viễn thông PTIT',
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
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.badge,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.cta,
    required this.accent,
    required this.accentDark,
    required this.cardBg,
    required this.badgeBg,
    required this.halo,
    required this.onTap,
  });

  final String badge;
  final String icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final String cta;
  final Color accent;
  final Color accentDark;
  final Color cardBg;
  final Color badgeBg;
  final Color halo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(icon, cacheWidth: 240),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: accentDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textBody),
              ),
              const SizedBox(height: 10),
              Divider(color: AppColors.dividerSubtle, height: 1),
              const SizedBox(height: 10),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textBody)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cta),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 16),
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
}
