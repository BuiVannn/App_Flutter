import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../settings/subscription.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final parentAsync = ref.watch(parentProfileProvider);
    final usageAsync = ref.watch(usageTodayProvider);
    final childrenAsync = ref.watch(childrenProvider);
    final tier = ref.watch(subscriptionTierProvider).asData?.value ?? 'basic';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Quản lý tài khoản'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(parentProfileProvider);
            ref.invalidate(usageTodayProvider);
            ref.invalidate(childrenProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _accountCard(context, parentAsync, tier, accent),
              const SizedBox(height: 16),
              _sectionLabel('LƯỢT SỬ DỤNG HÔM NAY', accent),
              _usageCard(usageAsync, accent),
              const SizedBox(height: 16),
              _sectionLabel('TÀI KHOẢN', accent),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Thông tin phụ huynh'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/account/parent'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.child_care_outlined),
                    title: const Text('Hồ sơ các bé'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(childrenAsync.maybeWhen(
                          data: (l) => '${l.length} bé', orElse: () => '')),
                      const Icon(Icons.chevron_right),
                    ]),
                    onTap: () => context.push('/account/children'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () => _openStore(),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('ĐẶT MUA THIẾT BỊ'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error)),
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('ĐĂNG XUẤT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t, Color accent) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(t,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5)),
      );

  Widget _accountCard(BuildContext context,
      AsyncValue<ParentProfile> async, String tier, Color accent) {
    return Card(
      child: async.when(
        loading: () => const ListTile(
            leading: CircularProgressIndicator(), title: Text('Đang tải…')),
        error: (err, st) => ListTile(
          leading: const Icon(Icons.error_outline, color: AppColors.error),
          title: const Text('Không tải được tài khoản'),
          subtitle: const Text('Kéo xuống để thử lại'),
        ),
        data: (p) {
          final plan = SubPlan.all.firstWhere(
              (s) => s.tier == tier,
              orElse: () => SubPlan.all.first);
          return ListTile(
            leading: CircleAvatar(
                backgroundColor: accent,
                child: const Icon(Icons.person, color: Colors.white)),
            title: Text(p.fullName.isEmpty ? p.email : p.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.email),
            trailing: Chip(
              backgroundColor: AppColors.kidBadgeBg,
              label: Text('★ ${plan.name}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ),
          );
        },
      ),
    );
  }

  Widget _usageCard(AsyncValue<UsageToday> async, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Text('Không tải được lượt dùng'),
          data: (u) {
            if (!u.available) {
              return const Row(children: [
                Icon(Icons.hourglass_empty, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Chưa có dữ liệu lượt dùng',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ]);
            }
            if (u.isUnlimited) {
              return Row(children: [
                Icon(Icons.all_inclusive, color: accent),
                const SizedBox(width: 8),
                Text('${u.used} câu hỏi hôm nay · Không giới hạn'),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${u.used} / ${u.quota} câu hỏi',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: u.fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.dividerLine,
                    color: accent),
              ),
              const SizedBox(height: 6),
              Text('Còn lại ${(u.quota! - u.used).clamp(0, u.quota!)} lượt',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]);
          },
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.parse('${ApiConfig.dashboardBaseUrl}/store');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để sử dụng tài khoản.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tokenStoreProvider).clear();
      await ref.read(activeChildStoreProvider).clear();
      if (context.mounted) context.go('/login');
    }
  }
}
