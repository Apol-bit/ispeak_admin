import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class ApiConfigurationException implements Exception {
  final String message;
  const ApiConfigurationException(this.message);

  @override
  String toString() => message;
}

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl => resolveBaseUrl(
    configuredBaseUrl: _configuredBaseUrl,
    releaseMode: kReleaseMode,
    webOrigin: kIsWeb ? Uri.base : null,
  );

  /// Local HTTP is allowed in release only when BOTH the web page and API
  /// are loopback. Deployed release pages still require explicit HTTPS.
  static String resolveBaseUrl({
    required String configuredBaseUrl,
    required bool releaseMode,
    Uri? webOrigin,
  }) {
    final localWeb =
        webOrigin != null &&
        webOrigin.scheme == 'http' &&
        _isLoopback(webOrigin.host);
    var value = configuredBaseUrl.trim();
    if (value.isEmpty) {
      if (releaseMode && !localWeb) {
        throw const ApiConfigurationException(
          'API_BASE_URL is required for deployed release builds. '
          'Configure an HTTPS API URL with --dart-define=API_BASE_URL=...',
        );
      }
      return localWeb
          ? Uri(
              scheme: 'http',
              host: webOrigin.host,
              port: 5000,
              path: '/api',
            ).toString()
          : 'http://localhost:5000/api';
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiConfigurationException(
        'API_BASE_URL must be an absolute HTTP(S) URL without credentials, query, or fragment.',
      );
    }
    if (releaseMode &&
        uri.scheme != 'https' &&
        !(localWeb && _isLoopback(uri.host))) {
      throw const ApiConfigurationException(
        'Release API_BASE_URL must use HTTPS. HTTP is allowed only for a '
        'local HTTP loopback Admin page calling a loopback API.',
      );
    }
    if (releaseMode && !localWeb && _isPrivateHost(uri.host)) {
      throw const ApiConfigurationException(
        'Deployed release API_BASE_URL must use a public HTTPS hostname.',
      );
    }
    if (value.endsWith('/')) value = value.substring(0, value.length - 1);
    return value;
  }

  static bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  static bool _isPrivateHost(String host) {
    var value = host.toLowerCase().replaceAll('[', '').replaceAll(']', '');
    if (value.endsWith('.')) value = value.substring(0, value.length - 1);
    if (value == 'localhost' ||
        value.endsWith('.localhost') ||
        value.endsWith('.local')) {
      return true;
    }
    if (RegExp(r'^[0-9.]+$').hasMatch(value)) {
      final parts = value.split('.').map(int.tryParse).toList();
      if (parts.length != 4 ||
          parts.any((part) => part == null || part < 0 || part > 255)) {
        return true;
      }
      final a = parts[0]!, b = parts[1]!;
      return a == 0 ||
          a == 10 ||
          a == 127 ||
          a >= 224 ||
          (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 168) ||
          (a == 100 && b >= 64 && b <= 127);
    }
    if (!value.contains(':')) return false;
    if (value.contains('.')) {
      final tail = value.substring(value.lastIndexOf(':') + 1);
      final bytes = tail.split('.').map(int.tryParse).toList();
      if (bytes.length != 4 ||
          bytes.any((part) => part == null || part < 0 || part > 255)) {
        return true;
      }
      value =
          '${value.substring(0, value.lastIndexOf(':') + 1)}'
          '${((bytes[0]! << 8) | bytes[1]!).toRadixString(16)}:'
          '${((bytes[2]! << 8) | bytes[3]!).toRadixString(16)}';
    }
    final halves = value.split('::');
    if (halves.length > 2) return true;
    final head = halves.first.isEmpty ? <String>[] : halves.first.split(':');
    final tail = halves.length == 2 && halves.last.isNotEmpty
        ? halves.last.split(':')
        : <String>[];
    final missing = 8 - head.length - tail.length;
    if (missing < 0 || (halves.length == 1 && missing != 0)) return true;
    final groups = [
      ...head,
      if (halves.length == 2) ...List.filled(missing, '0'),
      ...tail,
    ].map((part) => int.tryParse(part, radix: 16)).toList();
    if (groups.length != 8 ||
        groups.any((part) => part == null || part < 0 || part > 65535)) {
      return true;
    }
    if (groups.take(7).every((part) => part == 0) && groups[7]! <= 1) {
      return true;
    }
    if ((groups[0]! & 0xfe00) == 0xfc00 ||
        (groups[0]! & 0xffc0) == 0xfe80 ||
        (groups[0]! & 0xffc0) == 0xfec0 ||
        (groups[0]! & 0xff00) == 0xff00) {
      return true;
    }
    if (groups.take(5).every((part) => part == 0) &&
        (groups[5] == 0xffff || groups[5] == 0)) {
      return _isPrivateHost(
        '${groups[6]! >> 8}.${groups[6]! & 255}.${groups[7]! >> 8}.${groups[7]! & 255}',
      );
    }
    return false;
  }
}
