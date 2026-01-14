import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:ermes_types/ermes_types.dart';

void main() {
  testCachingRepository(
    'ErmesCachingService',
    () => ErmesCachingService<MessageType>(ErmesCachingRepository(100)),
  );
}
