library;

class CoreException implements Exception {
  CoreException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final suffix = cause != null ? ' (cause: $cause)' : '';
    return 'CoreException: $message$suffix';
  }
}
