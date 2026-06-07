import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../settings/subscription.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Future<void> _emailUpgrade() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ctslab@ptit.vn',
      queryParameters: {'subject': 'Nâng cấp gói PTalk'},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showUpgradeDialog(BuildContext context, SubPlan plan) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nâng cấp gói'),
        content: const Text(
            'Tính năng thanh toán đang được hoàn thiện.\n\nVui lòng liên hệ ctslab@ptit.vn để nâng cấp gói.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _emailUpgrade();
              },
              child: const Text('Gửi email')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElder = ServerConfig.activeMode == AppMode.elderCare;
    final accent =
        isElder ? AppColors.accentElderDark : AppColors.accentKidDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Gói Đăng Ký')),
      body: FutureBuilder<String?>(
        future: ref.read(tokenStoreProvider).accessToken,
        builder: (_, snap) {
          final currentTier = resolveTier(snap.data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Các gói chỉ khác nhau ở số câu hỏi mỗi ngày.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ...SubPlan.all.map((p) => _planCard(context, p, currentTier, accent)),
              const SizedBox(height: 8),
              const Center(
                child: Text('Liên hệ ctslab@ptit.vn để được hỗ trợ nâng cấp.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _planCard(
      BuildContext context, SubPlan plan, String currentTier, Color accent) {
    final curRank = SubPlan.rank(currentTier);
    final planRank = SubPlan.rank(plan.tier);
    final isCurrent = plan.tier == currentTier;
    final isLower = planRank < curRank;

    String label;
    VoidCallback? onPressed;
    if (isCurrent) {
      label = 'Đang dùng';
      onPressed = null;
    } else if (isLower) {
      label = 'Bạn đang dùng gói cao hơn';
      onPressed = null;
    } else {
      label = 'Nâng cấp ${plan.name}';
      onPressed = () => _showUpgradeDialog(context, plan);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: accent, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accent)),
                const SizedBox(width: 8),
                if (plan.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(plan.badge!,
                        style: TextStyle(fontSize: 11, color: accent)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.quota, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(plan.price,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: onPressed == null ? Colors.grey : accent),
                onPressed: onPressed,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
