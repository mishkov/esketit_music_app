final class BaseUriConfiguration {
  static const String baseUrlEnvironmentKey = 'BASE_URL';
  static const String defaultBaseUrl = 'http://46.101.162.92';

  const BaseUriConfiguration._();

  static Uri fromEnvironment() {
    final configuredBaseUrl = const String.fromEnvironment(
      baseUrlEnvironmentKey,
      defaultValue: defaultBaseUrl,
    );

    return parse(configuredBaseUrl);
  }

  static Uri parse(String configuredBaseUrl) {
    final uri = Uri.parse(configuredBaseUrl);
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw FormatException(
        'BASE_URL must include a scheme and host: $configuredBaseUrl',
      );
    }

    return uri;
  }
}
