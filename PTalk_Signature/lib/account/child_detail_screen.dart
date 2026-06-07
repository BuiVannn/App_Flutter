import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final async = ref.watch(childDetailProvider(childId));
    final activeId = ref.watch(activeChildProvider).asData?.value?.childId;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Thông tin bé'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: TextButton(
                onPressed: () => ref.invalidate(childDetailProvider(childId)),
                child: const Text('Không tải được. Thử lại')),
          ),
          data: (c) {
            final isActive = c.id == activeId;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Center(
                  child: Column(children: [
                    CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.kidBadgeBg,
                        child: Icon(Icons.child_care, color: accent, size: 40)),
                    const SizedBox(height: 12),
                    Text(c.fullName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    if (isActive) ...[
                      const SizedBox(height: 6),
                      Chip(
                        backgroundColor: AppColors.kidBadgeBg,
                        label: Text('✓ Đang dùng',
                            style: TextStyle(
                                color: accent, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(children: [
                    _row('Họ và tên', c.fullName.isEmpty ? '—' : c.fullName),
                    const Divider(height: 1),
                    _row('Lớp', c.gradeLabel),
                    const Divider(height: 1),
                    _row('Ngày sinh', c.dateOfBirth ?? '—'),
                    const Divider(height: 1),
                    _row('Quê quán', c.hometown ?? '—'),
                    const Divider(height: 1),
                    _row('Bộ sách', c.curriculumLabel),
                    const Divider(height: 1),
                    _row('Quan hệ', c.relationshipLabel),
                  ]),
                ),
                const SizedBox(height: 16),
                if (!isActive)
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () async {
                        await setActiveChild(ref, c);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Đang dùng app với hồ sơ ${c.fullName}')));
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('CHỌN BÉ NÀY DÙNG APP'),
                    ),
                  ),
                const SizedBox(height: 12),
                const Row(children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Thông tin đồng bộ từ hệ thống.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
        title: Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
