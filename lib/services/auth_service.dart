import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

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

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<Map<String, String>> authHeaders({bool json = false}) async {
    final token = await getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Revalidates the signature, expiration, account state, and role on the API.
  static Future<Map<String, String>?> validateSession() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        // A transient backend failure does not invalidate saved credentials.
        // Return no validated user until the backend can verify the session.
        if (response.statusCode == 401 ||
            (response.statusCode == 403 &&
                jsonDecode(response.body)['message'] == 'This account is not active')) {
          await clearSession();
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final role = user['role']?.toString() ?? 'user';
      if (role != 'admin' && role != 'validator') {
        await clearSession();
        return null;
      }

      final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
          .trim();
      final email = user['email']?.toString() ?? '';
      await saveSession(
        token: token,
        userName: name.isEmpty
            ? (user['username']?.toString() ?? 'User')
            : name,
        userEmail: email,
        userRole: role,
      );
      return {
        'token': token,
        'userName': name.isEmpty
            ? (user['username']?.toString() ?? 'User')
            : name,
        'userEmail': email,
        'userRole': role,
      };
    } catch (_) {
      return null;
    }
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
