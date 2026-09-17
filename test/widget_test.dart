import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispeak_admin_panel/screens/login_screen.dart';

void main() {
  testWidgets('admin login screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('iSpeak Admin'), findsOneWidget);
    expect(find.text('Authorized Personnel Only'), findsOneWidget);
  });
}
