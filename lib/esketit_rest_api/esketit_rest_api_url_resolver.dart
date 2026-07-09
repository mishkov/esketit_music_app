Uri resolveEsketitRestApiUrl(
  Uri baseUri,
  String value, {
  String? fallbackDirectory,
}) {
  final parsed = Uri.tryParse(value);
  if (parsed != null && parsed.hasScheme) {
    return parsed;
  }
  if (value.isEmpty) {
    return Uri();
  }
  if (value.startsWith('/')) {
    return baseUri.resolve(value);
  }
  if (fallbackDirectory == null) {
    return baseUri.resolve(value);
  }

  return baseUri.resolve('$fallbackDirectory/${Uri.encodeComponent(value)}');
}

String resolveEsketitRestApiUrlString(
  Uri baseUri,
  String value, {
  String? fallbackDirectory,
}) {
  if (value.isEmpty) {
    return value;
  }

  return resolveEsketitRestApiUrl(
    baseUri,
    value,
    fallbackDirectory: fallbackDirectory,
  ).toString();
}
