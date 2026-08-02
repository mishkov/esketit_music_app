String authorRoutePath(int authorId) {
  return '/authors/$authorId';
}

int? authorIdFromRouteName(String routeName) {
  final uri = Uri.tryParse(routeName);
  final segments = uri?.pathSegments ?? const <String>[];

  if (segments.length != 2 || segments.first != 'authors') {
    return null;
  }

  final authorId = int.tryParse(segments[1]);

  return authorId != null && authorId > 0 ? authorId : null;
}
