import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ptalk_signature/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows SSO + guest buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('ĐĂNG NHẬP VỚI SSO'), findsOneWidget);
    expect(find.text('VÀO XEM THỬ'), findsOneWidget);
    expect(find.text('CHÀO MỪNG\nBẠN TRỞ LẠI'), findsOneWidget);
  });
}
