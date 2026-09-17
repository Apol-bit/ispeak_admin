import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isEmpty) {
      if (kReleaseMode) {
        throw StateError('API_BASE_URL is required for release builds');
      }
      return 'http://localhost:5000/api';
    }
    final value = _configuredBaseUrl.endsWith('/')
        ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
        : _configuredBaseUrl;
    if (kReleaseMode && Uri.tryParse(value)?.scheme != 'https') {
      throw StateError('Release API_BASE_URL must use HTTPS');
    }
    return value;
  }
}
