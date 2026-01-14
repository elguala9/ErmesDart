import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_test/ermes_test.dart';

void main() {
  testIdHandlerStorage(
    'IdHandlerStorageService (delegating)',
    IdHandlerStorageRepository.new,
  );
}
