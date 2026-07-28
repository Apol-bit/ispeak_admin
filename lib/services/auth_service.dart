import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent authentication session using SharedPreferences.
/// On web, this uses localStorage under the hood — survives page reloads.
class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';

  /// Save the login session after successful authentication.
  static Future<void> saveSession({
    required String token,
    required String userName,
    required String userEmail,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setString(_keyUserRole, userRole);
  }

  /// Check if a valid session exists.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  /// Retrieve the saved session data. Returns null if no session exists.
  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);

    if (token == null || token.isEmpty) return null;

    return {
      'token': token,
      'userName': prefs.getString(_keyUserName) ?? 'User',
      'userEmail': prefs.getString(_keyUserEmail) ?? '',
      'userRole': prefs.getString(_keyUserRole) ?? 'user',
    };
  }

  /// Clear the saved session (logout).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
  }
}
