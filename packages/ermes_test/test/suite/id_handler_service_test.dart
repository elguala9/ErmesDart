// Test file for IdHandlerService concrete implementation
// Tests the interface contract using testIdHandlerService from ermes_test

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_test/ermes_test.dart';

void main() {
  testIdHandlerService(
    'IdHandlerService',
    () => IdHandlerService(repo: IdHandlerRepository()),
  );
}
