import 'injection_cipher_test.dart';
import 'injection_id_handler_test.dart';
import 'injection_message_control_test.dart';
import 'injection_orc_ermes_test.dart';
import 'injection_storage_test.dart';

/// Runs every dependency-injection suite.
///
/// Replaces the former `orcermes_initial_point_tests.dart`: the singleton and
/// registry variants it aggregated collapsed into one keyed suite per package
/// when singleton_manager 2.x replaced the two containers with one keyed
/// registry.
Future<void> main() async {
  testInjectionStorage();
  testInjectionMessageControl();
  await testInjectionCipher();
  testInjectionIdHandler();
  testInjectionOrcErmes();
}
