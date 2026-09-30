class AppConfig {
  static const serverUrl = String.fromEnvironment('PARSE_SERVER_URL');
  static const applicationId = String.fromEnvironment('PARSE_APPLICATION_ID');
  static const clientKey = String.fromEnvironment('PARSE_CLIENT_KEY');
  static const _termsVersion = String.fromEnvironment('TERMS_VERSION');
  static const _privacyVersion = String.fromEnvironment('PRIVACY_VERSION');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isConfigured =>
      serverUrl.startsWith('https://') &&
      applicationId.isNotEmpty;

  static String get termsVersion =>
      _termsVersion.isEmpty ? 'testing-v1' : _termsVersion;

  static String get privacyVersion =>
      _privacyVersion.isEmpty ? 'testing-v1' : _privacyVersion;

  static bool get legalDocumentsPublished =>
      termsUrl.startsWith('https://') && privacyUrl.startsWith('https://');

  static bool get canRegister => isConfigured;
}
