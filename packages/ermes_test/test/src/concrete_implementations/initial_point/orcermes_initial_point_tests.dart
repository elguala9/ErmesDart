import 'initial_point_ermes_usage_test.dart';
import 'initial_point_integration_test.dart';
import 'orc_ermes_init_factory_test.dart';

void main() {
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  testInitialPointStorageRegistry();
  testInitialPointMessageControlRegistry();
  testInitialPointIdHandlerRegistry();

  testInitialPointErmesUsage();
  testInitialPointErmesRegistryUsage();

  testOrcErmesInitFactorySingleton();
  testOrcErmesInitFactoryInstance();
}
