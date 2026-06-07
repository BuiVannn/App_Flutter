import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../widgets/gradient_background.dart';
import 'account_providers.dart';

class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.accentKidDark;
    final async = ref.watch(parentProfileProvider);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Thông tin phụ huynh'),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              const Text('Không tải được thông tin'),
              TextButton(
                  onPressed: () => ref.invalidate(parentProfileProvider),
                  child: const Text('Thử lại')),
            ]),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: Column(children: [
                  CircleAvatar(
                      radius: 36,
                      backgroundColor: accent,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 40)),
                  const SizedBox(height: 12),
                  Text(p.fullName.isEmpty ? p.email : p.fullName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Text('Chủ tài khoản',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(children: [
                  _row('Họ và tên', p.fullName.isEmpty ? '—' : p.fullName),
                  const Divider(height: 1),
                  _row('Số điện thoại', (p.phone?.isEmpty ?? true) ? '—' : p.phone!),
                  const Divider(height: 1),
                  _row('Email', p.email),
                ]),
              ),
              const SizedBox(height: 16),
              const _ReadOnlyHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
        title: Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _ReadOnlyHint extends StatelessWidget {
  const _ReadOnlyHint();
  @override
  Widget build(BuildContext context) => const Row(children: [
        Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Thông tin đồng bộ từ hệ thống. Để chỉnh sửa, dùng Web Dashboard.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ]);
}
