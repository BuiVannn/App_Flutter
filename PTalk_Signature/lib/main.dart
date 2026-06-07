import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'spike/spike_screen.dart';

void main() => runApp(const ProviderScope(child: PtalkSignatureApp()));

class PtalkSignatureApp extends StatelessWidget {
  const PtalkSignatureApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PTalk Signature',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1FAA59), useMaterial3: true),
        home: const SpikeScreen(),
      );
}
