library;

class MessageControlException implements Exception {
  MessageControlException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final suffix = cause != null ? ' (cause: $cause)' : '';
    return 'MessageControlException: $message$suffix';
  }
}
