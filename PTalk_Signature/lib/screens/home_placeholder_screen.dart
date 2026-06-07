import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import '../core/providers.dart';
import '../widgets/gradient_background.dart';

/// Tạm thời thay cho MainActivity (sẽ làm đầy đủ ở G3: voice + hiệu ứng).
/// Hiện đủ để kiểm thử luồng: hiện chế độ đã chọn, mở spike audio, đăng xuất.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ServerConfig.activeMode;
    final store = ref.read(tokenStoreProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(mode.brandTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await store.clear();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mode.greetingText,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(mode.subGreetingText,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: store.username,
                  builder: (_, snap) => Text(
                    snap.data != null ? 'Xin chào, ${snap.data}' : 'Khách',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Text('WS: ${mode.wsUrl()}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/spike'),
                  icon: const Icon(Icons.mic),
                  label: const Text('Mở Audio Spike (test voice)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/mode-select'),
                  child: const Text('Đổi chế độ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
