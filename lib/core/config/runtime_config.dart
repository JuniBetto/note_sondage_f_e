class RuntimeConfig {
  static const String defaultGoogleWebClientId =
      '907402131431-pqiaudv68qea3uufo7ectug6cnst58uf.apps.googleusercontent.com';
  static const String defaultGoogleServerClientId =
      '907402131431-pqiaudv68qea3uufo7ectug6cnst58uf.apps.googleusercontent.com';
  static const String defaultSentryDsn = 'YOUR_DSN_HERE';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
    defaultValue: defaultGoogleServerClientId,
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: defaultSentryDsn,
  );

  static String normalizeBaseUrl(String url) => url.replaceAll(
    RegExp(r'/+$'),
    '',
  );

  static String get resolvedApiBaseUrl => normalizeBaseUrl(apiBaseUrl.trim());

  static bool get hasCustomApiBaseUrl => resolvedApiBaseUrl.isNotEmpty;
}
