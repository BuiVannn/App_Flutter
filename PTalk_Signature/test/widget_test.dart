import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ptalk_signature/main.dart';

void main() {
  testWidgets('SpikeScreen renders with start button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PtalkSignatureApp()));
    expect(find.text('Audio Spike'), findsOneWidget);
    expect(find.text('Bắt đầu nói'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
