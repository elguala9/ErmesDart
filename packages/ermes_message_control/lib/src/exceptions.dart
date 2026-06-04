library;

import 'package:iermes/iermes.dart';

class MessageControlException extends ErmesException {
  MessageControlException(super.message, [super.cause]);

  @override
  String get tag => 'MessageControlException';
}
