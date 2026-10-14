import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ispeak_admin_panel/config/api_config.dart';
import 'package:ispeak_admin_panel/screens/login_screen.dart';

void main() {
  for (final scenario in ['credentials', 'network', 'configuration']) {
    testWidgets('login distinguishes $scenario errors', (tester) async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/login');
        switch (scenario) {
          case 'credentials':
            return http.Response(
              '{"message":"Invalid email or password"}',
              401,
            );
          case 'network':
            throw http.ClientException('Connection refused');
          default:
            throw const ApiConfigurationException(
              'Release API_BASE_URL must use HTTPS.',
            );
        }
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.invalid',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'nonexistent-test-account',
        );
        await tester.ensureVisible(find.text('Log In'));
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();
        final network = find.text(
          'Network error. Check your connection to the server.',
        );
        if (scenario == 'credentials') {
          expect(find.text('Invalid email or password'), findsOneWidget);
          expect(network, findsNothing);
        } else if (scenario == 'network') {
          expect(network, findsOneWidget);
        } else {
          expect(
            find.textContaining('API configuration error:'),
            findsOneWidget,
          );
          expect(network, findsNothing);
        }
        expect(find.text('Log In'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => client);
    });
  }
}
