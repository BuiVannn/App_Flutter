import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ptalk_core/ptalk_core.dart';
import 'router.dart';

void main() => runApp(const ProviderScope(child: PtalkSignatureApp()));

class PtalkSignatureApp extends StatelessWidget {
  const PtalkSignatureApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'PTalk Signature',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: AppColors.accentKid,
          scaffoldBackgroundColor: Colors.transparent,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        routerConfig: appRouter,
      );
}
