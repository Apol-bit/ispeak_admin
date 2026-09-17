import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ispeak_admin_panel/services/auth_service.dart';

void main() {
  test('admin bearer token is persisted, attached, and cleared', () async {
    SharedPreferences.setMockInitialValues({});

    await AuthService.saveSession(
      token: 'test-token',
      userName: 'Test Admin',
      userEmail: 'admin@example.test',
      userRole: 'admin',
    );
    final headers = await AuthService.authHeaders();
    expect(headers['Authorization'], 'Bearer test-token');

    await AuthService.clearSession();
    expect(await AuthService.getToken(), isNull);
  });
}
