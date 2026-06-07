import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'router.dart';
import 'settings/settings_providers.dart';

void main() => runApp(const ProviderScope(child: PtalkSignatureApp()));

class PtalkSignatureApp extends ConsumerWidget {
  const PtalkSignatureApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'PTalk Signature',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: AppColors.accentKid,
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: AppColors.accentKid,
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: appRouter,
    );
  }
}
