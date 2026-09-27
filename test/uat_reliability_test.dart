import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/services/api_client.dart';
import 'package:ispeak_admin_panel/services/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'valid-token'});
    ApiClient.onAuthenticationExpired = null;
  });
  for (final status in [500, 502, 503, 504, 429]) {
    test('HTTP $status preserves administrator credentials', () async {
      await http.runWithClient(() async {
        expect(await AuthService.validateSession(), isNull);
        expect(await AuthService.getToken(), 'valid-token');
        var expired = false;
        ApiClient.onAuthenticationExpired = () async => expired = true;
        await ApiClient.get(Uri.parse('https://example.test/stats'));
        expect(await AuthService.getToken(), 'valid-token');
        expect(expired, isFalse);
      }, () => MockClient((_) async => http.Response('{}', status)));
    });
  }
  test('actual 401 clears the session', () async {
    await http.runWithClient(() async {
      expect(await AuthService.validateSession(), isNull);
      expect(await AuthService.getToken(), isNull);
    }, () => MockClient((_) async => http.Response('{}', 401)));
  });
}
