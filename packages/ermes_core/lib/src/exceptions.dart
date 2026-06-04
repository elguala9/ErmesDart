library;

import 'package:iermes/iermes.dart';

class CoreException extends ErmesException {
  CoreException(super.message, [super.cause]);

  @override
  String get tag => 'CoreException';
}
