final class BaseUriConfiguration {
  static const String baseUrlEnvironmentKey = 'BASE_URL';
  static const String defaultBaseUrl = 'http://46.101.162.92/api/';

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
    final isAbsoluteHttpUri =
        (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    final isRootRelativeUri =
        !uri.hasScheme &&
        uri.host.isEmpty &&
        uri.path.startsWith('/') &&
        !uri.hasQuery &&
        !uri.hasFragment;

    if (!isAbsoluteHttpUri && !isRootRelativeUri) {
      throw FormatException(
        'BASE_URL must be an absolute http(s) URL or root-relative path: '
        '$configuredBaseUrl',
      );
    }

    return _withApiSuffix(uri);
  }

  static Uri _withApiSuffix(Uri uri) {
    final path = uri.path;
    final directoryPath = path.endsWith('/') ? path : '$path/';
    final apiPath = directoryPath.endsWith('/api/')
        ? directoryPath
        : '${directoryPath == '/' ? '/' : directoryPath}api/';

    return uri.replace(path: apiPath);
  }
}
