import 'package:flutter/foundation.dart';

enum AppEnvironment {
  dev('Dev'),
  test('Test'),
  prod('Prod');

  const AppEnvironment(this.sentryName);

  final String sentryName;
}

class RuntimeConfig {
  static const String defaultGoogleWebClientId =
      '907402131431-pqiaudv68qea3uufo7ectug6cnst58uf.apps.googleusercontent.com';
  static const String defaultGoogleServerClientId =
      '907402131431-pqiaudv68qea3uufo7ectug6cnst58uf.apps.googleusercontent.com';
  static const String defaultSentryDsn = 'YOUR_DSN_HERE';
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: defaultGoogleServerClientId,
  );

  static const String emailConfirmationUrl = String.fromEnvironment(
    'EMAIL_CONFIRMATION_URL',
    defaultValue: '',
  );

  static const String passwordResetUrl = String.fromEnvironment(
    'PASSWORD_RESET_URL',
    defaultValue: '',
  );

  static const String appleStoreUrl = String.fromEnvironment(
    'APPLE_STORE_URL',
    defaultValue: '',
  );

  static const String androidStoreUrl = String.fromEnvironment(
    'ANDROID_STORE_URL',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: defaultSentryDsn,
  );

  static String normalizeBaseUrl(String url) =>
      url.replaceAll(RegExp(r'/+$'), '');

  static AppEnvironment get currentEnvironment {
    final explicitEnvironment = _environmentFromString(appEnv);
    if (explicitEnvironment != null) {
      return explicitEnvironment;
    }

    if (!kReleaseMode) {
      return AppEnvironment.dev;
    }

    final configuredApiUri = Uri.tryParse(resolvedApiBaseUrl);
    final configuredApiScheme = configuredApiUri?.scheme.toLowerCase() ?? '';
    final configuredApiHost = configuredApiUri?.host.toLowerCase() ?? '';

    if (_isPrivateOrLanHost(configuredApiHost)) {
      return configuredApiScheme == 'https'
          ? AppEnvironment.test
          : AppEnvironment.dev;
    }

    if (kIsWeb) {
      final appScheme = Uri.base.scheme.toLowerCase();
      final appHost = Uri.base.host.toLowerCase();

      if (_isPrivateOrLanHost(appHost)) {
        return appScheme == 'https' ? AppEnvironment.test : AppEnvironment.dev;
      }
    }

    return AppEnvironment.prod;
  }

  static String get resolvedApiBaseUrl => normalizeBaseUrl(apiBaseUrl.trim());
  static String get resolvedEmailConfirmationUrl => emailConfirmationUrl.trim();
  static String get resolvedPasswordResetUrl => passwordResetUrl.trim();
  static String get resolvedAppleStoreUrl => appleStoreUrl.trim();
  static String get resolvedAndroidStoreUrl => androidStoreUrl.trim();
  static String get sentryEnvironment => currentEnvironment.sentryName;

  static bool get hasCustomApiBaseUrl => resolvedApiBaseUrl.isNotEmpty;
  static bool get hasCustomEmailConfirmationUrl =>
      resolvedEmailConfirmationUrl.isNotEmpty;
  static bool get hasCustomPasswordResetUrl =>
      resolvedPasswordResetUrl.isNotEmpty;
  static bool get hasAppleStoreUrl => resolvedAppleStoreUrl.isNotEmpty;
  static bool get hasAndroidStoreUrl => resolvedAndroidStoreUrl.isNotEmpty;

  static AppEnvironment? _environmentFromString(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'test':
      case 'qa':
      case 'staging':
        return AppEnvironment.test;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return null;
    }
  }

  static bool _isPrivateOrLanHost(String host) {
    if (host.isEmpty) {
      return false;
    }

    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return true;
    }

    if (host.endsWith('.lan') || host.endsWith('.local')) {
      return true;
    }

    if (host.startsWith('10.') || host.startsWith('192.168.')) {
      return true;
    }

    final octets = host.split('.');
    if (octets.length != 4) {
      return false;
    }

    final firstOctet = int.tryParse(octets[0]);
    final secondOctet = int.tryParse(octets[1]);
    if (firstOctet == null || secondOctet == null) {
      return false;
    }

    return firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31;
  }
}
