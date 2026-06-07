import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ptalk_signature/main.dart';

void main() {
  testWidgets('SpikeScreen renders with start button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PtalkSignatureApp()));
    expect(find.text('Audio Spike'), findsOneWidget);
    expect(find.text('Loopback (offline)'), findsOneWidget);
    expect(find.text('Server (WS)'), findsOneWidget);
    expect(find.text('Dừng'), findsOneWidget);
  });
}
