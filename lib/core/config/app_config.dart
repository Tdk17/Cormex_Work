class AppConfig {
  static const serverUrl = String.fromEnvironment('PARSE_SERVER_URL');
  static const applicationId = String.fromEnvironment('PARSE_APPLICATION_ID');
  static const clientKey = String.fromEnvironment('PARSE_CLIENT_KEY');
  static const termsVersion = String.fromEnvironment('TERMS_VERSION');
  static const privacyVersion = String.fromEnvironment('PRIVACY_VERSION');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isConfigured =>
      serverUrl.startsWith('https://') &&
      applicationId.isNotEmpty;

  static bool get canRegister =>
      isConfigured &&
      termsVersion.isNotEmpty &&
      privacyVersion.isNotEmpty &&
      termsUrl.startsWith('https://') &&
      privacyUrl.startsWith('https://');
}
