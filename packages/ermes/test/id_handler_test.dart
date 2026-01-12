import 'package:ermes/src/ermes_implementation/id_handler/id_handler_repository.dart';
import 'package:ermes/src/ermes_implementation/id_handler/id_handler_service.dart';
import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';

void main() {
  // IdHandlerRepository Tests
  testIdHandlerRepository<IdHandlerRepository>(
    'IdHandlerRepository',
    IdHandlerRepository.new,
  );

  // IdHandlerService Tests
  testIdHandlerService<IdHandlerService>(
    'IdHandlerService',
    () => IdHandlerService(repo: IdHandlerRepository()),
  );

  // IdHandlerRepository with Caching Tests
  testIdHandlerWithCaching(
    'IdHandlerRepository with ErmesCachingRepository',
    IdHandlerRepository.new,
    () => createErmesCachingRepository<Map<String, dynamic>>(),
  );
}
