library;

import 'package:iermes/iermes.dart';

class SignalingException extends ErmesException {
  SignalingException(super.message, [super.cause]);

  @override
  String get tag => 'SignalingException';
}
