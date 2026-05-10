library;

class SignalingException implements Exception {
  SignalingException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final suffix = cause != null ? ' (cause: $cause)' : '';
    return 'SignalingException: $message$suffix';
  }
}
