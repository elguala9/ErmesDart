import 'initial_point_integration_test.dart';

Future<void> main() async {
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  await testInitialPointSignaling();
}
