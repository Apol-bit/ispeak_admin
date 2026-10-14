import 'package:flutter_test/flutter_test.dart';
import 'package:ispeak_admin_panel/config/api_config.dart';

void main() {
  test('deployed releases reject local/private HTTPS endpoints', () {
    for (final host in [
      'localhost',
      'localhost.',
      'dev.local',
      '127.0.0.1',
      '127.1',
      '10.0.0.1',
      '172.16.0.1',
      '192.168.1.1',
      '169.254.1.1',
      '100.64.1.1',
      '[::]',
      '[::1]',
      '[0:0:0:0:0:0:0:1]',
      '[fd00::1]',
      '[fe80::1]',
      '[fec0::1]',
      '[::ffff:192.168.1.1]',
      '[::ffff:c0a8:101]',
    ]) {
      expect(
        () => ApiConfig.resolveBaseUrl(
          configuredBaseUrl: 'https://$host/api',
          releaseMode: true,
          webOrigin: Uri.parse('https://admin.example.test'),
        ),
        throwsA(isA<ApiConfigurationException>()),
        reason: host,
      );
    }
    expect(
      ApiConfig.resolveBaseUrl(
        configuredBaseUrl: 'https://api.example.test/api',
        releaseMode: true,
        webOrigin: Uri.parse('https://admin.example.test'),
      ),
      'https://api.example.test/api',
    );
  });
  String resolve({String url = '', bool release = true, String? origin}) =>
      ApiConfig.resolveBaseUrl(
        configuredBaseUrl: url,
        releaseMode: release,
        webOrigin: origin == null ? null : Uri.parse(origin),
      );

  test('debug keeps the existing localhost default', () {
    expect(resolve(release: false), 'http://localhost:5000/api');
  });

  test('local web release defaults to port 5000, independent of web port', () {
    for (final port in [51328, 62719]) {
      expect(
        resolve(origin: 'http://localhost:$port/'),
        'http://localhost:5000/api',
      );
      expect(
        resolve(origin: 'http://127.0.0.1:$port/'),
        'http://127.0.0.1:5000/api',
      );
      expect(resolve(origin: 'http://[::1]:$port/'), 'http://[::1]:5000/api');
    }
  });

  test('explicit local API port supported only from HTTP loopback page', () {
    expect(
      resolve(
        url: 'http://127.0.0.1:5001/api/',
        origin: 'http://localhost:53281/',
      ),
      'http://127.0.0.1:5001/api',
    );
    for (final origin in [
      null,
      'https://admin.example.test/',
      'http://admin.example.test/',
      'https://localhost:53281/',
    ]) {
      expect(
        () => resolve(url: 'http://localhost:5000/api', origin: origin),
        throwsA(isA<ApiConfigurationException>()),
      );
    }
  });

  test('deployed release requires an explicit API URL', () {
    for (final origin in [
      null,
      'https://admin.example.test/',
      'http://admin.example.test/',
      'file:///index.html',
      'https://localhost/',
    ]) {
      expect(
        () => resolve(origin: origin),
        throwsA(isA<ApiConfigurationException>()),
      );
    }
  });

  test(
    'local release cannot target remote HTTP or lookalike loopback hosts',
    () {
      for (final host in [
        'api.example.test',
        '192.168.1.4',
        'localhost.example.test',
        '127.0.0.1.example.test',
        '0.0.0.0',
      ]) {
        expect(
          () => resolve(
            url: 'http://$host:5000/api',
            origin: 'http://localhost:1234/',
          ),
          throwsA(isA<ApiConfigurationException>()),
        );
        expect(
          () => resolve(origin: 'http://$host:1234/'),
          throwsA(isA<ApiConfigurationException>()),
        );
      }
    },
  );

  test(
    'explicit HTTPS works for debug, local release, and deployed release',
    () {
      for (final origin in [
        null,
        'http://localhost:51328/',
        'https://admin.example.test/',
      ]) {
        expect(
          resolve(url: 'https://api.example.test/api/', origin: origin),
          'https://api.example.test/api',
        );
        expect(
          resolve(
            url: 'https://api.example.test/api',
            release: false,
            origin: origin,
          ),
          'https://api.example.test/api',
        );
      }
    },
  );

  test(
    'malformed and credential-bearing configuration fails before requests',
    () {
      for (final url in [
        'api.example.test',
        '/api',
        'ftp://localhost/api',
        'https://',
        'https://user:secret@example.test/api',
        'https://api.example.test/api?x=1',
        'https://api.example.test/api#fragment',
      ]) {
        expect(
          () => resolve(url: url),
          throwsA(isA<ApiConfigurationException>()),
        );
      }
    },
  );
}
