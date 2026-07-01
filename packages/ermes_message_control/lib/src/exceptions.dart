library;

import 'package:iermes/iermes.dart';

/// Exception thrown when a message-control operation fails.
class MessageControlException extends ErmesException {
  /// Creates the exception with a [message] and optional underlying [cause].
  MessageControlException(super.message, [super.cause]);

  /// Identifier tag used to classify this exception type.
  @override
  String get tag => 'MessageControlException';
}
