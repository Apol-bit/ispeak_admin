import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  /// Sends the email and password to the Node.js backend to authenticate the user.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'), // Update this if your login route is different (e.g., /user/login)
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // If the server responds with a 200 OK, return the parsed data (token, user info, etc.)
      if (response.statusCode == 200) {
        return data;
      } else {
        // If the server responds with an error (e.g., 400 or 403), return the error message
        return {
          'message': data['message'] ?? 'Login failed. Please check your credentials.',
        };
      }
    } catch (e) {
      // Catches network errors (like the server being offline or wrong IP address)
      return {
        'message': 'Network error. Please check your connection to the server.',
      };
    }
  }
}