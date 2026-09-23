abstract interface class AuthSessionDiagnostics {
  Future<void> record(String message, Map<String, Object?> data);

  Future<Object> failure({
    required String operation,
    required String message,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> data = const {},
  });

  Future<void> setUserId(String? userId);
}
