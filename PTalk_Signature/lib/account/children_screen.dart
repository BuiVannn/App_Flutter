import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final childrenAsync = ref.watch(childrenProvider);
    final activeAsync = ref.watch(activeChildProvider);
    final activeId = activeAsync.asData?.value?.childId;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Hồ sơ các bé'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: TextButton(
                onPressed: () => ref.invalidate(childrenProvider),
                child: const Text('Không tải được. Thử lại')),
          ),
          data: (children) {
            if (children.isEmpty) {
              return const _Empty();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _label('TẤT CẢ CÁC BÉ (${children.length})', accent),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _childTile(context, ref, children[i],
                            isActive: children[i].id == activeId, accent: accent),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chọn bé đang dùng để AI dạy đúng lớp và bộ sách của bé đó.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String t, Color accent) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: TextStyle(
                color: accent, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _childTile(BuildContext context, WidgetRef ref, ChildProfile c,
      {required bool isActive, required Color accent}) {
    return ListTile(
      leading: Icon(
          isActive ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isActive ? accent : AppColors.textMuted),
      title: Text(c.fullName.isEmpty ? 'Bé' : c.fullName),
      subtitle: Text('${c.gradeLabel} · ${c.relationshipLabel}'),
      trailing: IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () => context.push('/account/children/${c.id}'),
      ),
      onTap: () async {
        await setActiveChild(ref, c);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đang dùng app với hồ sơ ${c.fullName}')),
          );
        }
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.child_care_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Chưa có hồ sơ bé',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Thêm hồ sơ bé trên Web Dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
}
