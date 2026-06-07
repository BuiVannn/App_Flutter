import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../settings/settings_providers.dart';
import '../widgets/gradient_background.dart';

const _appVersion = '1.0.0 (Flutter)';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emergencyCtrl = TextEditingController();
  bool _emergencyLoaded = false;

  @override
  void dispose() {
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElder = ServerConfig.activeMode == AppMode.elderCare;
    final accent =
        isElder ? AppColors.accentElderDark : AppColors.accentKidDark;
    final themeMode = ref.watch(themeModeProvider);
    final store = ref.read(tokenStoreProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Cài đặt'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
          _section('TÀI KHOẢN', accent),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: accent,
                  child: const Icon(Icons.person, color: Colors.white)),
              title: const Text('Quản lý tài khoản'),
              subtitle: const Text('Hồ sơ phụ huynh, các bé, gói cước'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account'),
            ),
          ),
          const SizedBox(height: 16),
          _section('GIAO DIỆN', accent),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (m) {
                if (m != null) ref.read(themeModeProvider.notifier).set(m);
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                      title: Text('Sáng'), value: ThemeMode.light),
                  RadioListTile<ThemeMode>(
                      title: Text('Tối'), value: ThemeMode.dark),
                  RadioListTile<ThemeMode>(
                      title: Text('Theo hệ thống'), value: ThemeMode.system),
                ],
              ),
            ),
          ),
          if (isElder) ...[
            const SizedBox(height: 16),
            _section('CHẾ ĐỘ ELDER CARE', accent),
            _emergencyCard(accent),
          ],
          const SizedBox(height: 16),
          _section('VỀ ỨNG DỤNG', accent),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Chính sách bảo mật'),
                  onTap: () => _openUrl('https://dashboard.ctslab.net/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Điều khoản sử dụng'),
                  onTap: () => _openUrl('https://dashboard.ctslab.net/terms'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Phiên bản'),
                  trailing: Text(_appVersion),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<bool>(
            future: store.isLoggedIn(),
            builder: (_, snap) {
              final loggedIn = snap.data ?? false;
              return SizedBox(
                height: 50,
                child: loggedIn
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error)),
                        onPressed: () => _confirmLogout(store),
                        icon: const Icon(Icons.logout),
                        label: const Text('ĐĂNG XUẤT'),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonDark),
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.vpn_key),
                        label: const Text('ĐĂNG NHẬP'),
                      ),
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Color accent) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(title,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5)),
      );

  Widget _emergencyCard(Color accent) {
    final storeAsync = ref.watch(settingsStoreProvider);
    return storeAsync.when(
      loading: () => const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()))),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        if (!_emergencyLoaded) {
          _emergencyCtrl.text = s.emergencyNumber;
          _emergencyLoaded = true;
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số gọi khẩn cấp',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Text(
                    'Nút gọi khẩn cấp trên màn hình chính sẽ quay số này.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emergencyCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () async {
                        await s.setEmergencyNumber(_emergencyCtrl.text);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã lưu số khẩn cấp')),
                        );
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(TokenStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content:
            const Text('Bạn sẽ cần đăng nhập lại để sử dụng tài khoản.'),
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
      await store.clear();
      await ActiveChildStore().clear();
      if (mounted) context.go('/login');
    }
  }
}
