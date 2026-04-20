import 'src/concrete_implementations/cipher/cipher_factories_test.dart';
import 'src/concrete_implementations/cipher/ecdh_key_exchange_test.dart';
import 'src/concrete_implementations/cipher/ermes_cipher_exceptions_test.dart';
import 'src/concrete_implementations/cipher/ermes_peer_cipher_impl_test.dart';
import 'src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart';
import 'src/concrete_implementations/core/ermes_book_impl_test.dart';
import 'src/concrete_implementations/core/ermes_connection_test.dart';
import 'src/concrete_implementations/core/ermes_deduplication_test.dart';
import 'src/concrete_implementations/core/ermes_encryption_decryption_test.dart';
import 'src/concrete_implementations/core/ermes_peer_test.dart';
import 'src/concrete_implementations/core/ermes_peer_retransmission_integration_test.dart';
import 'src/concrete_implementations/core/ermes_service_retransmission_test.dart';
import 'src/concrete_implementations/core/serialization_registry_test.dart';
import 'src/concrete_implementations/initial_point/initial_point_integration_test.dart';
import 'src/concrete_implementations/orchestration/orchestration_tests.dart' as orchestration;

Future<void> main() async {
  // Esegui test per le implementazioni concrete
  testErmesCipherExceptions();
  testErmesPeerCipherImplementation();
  testECDHKeyExchange();
  testCipherFactories();
  testTwoPeerCipherExchange();
  testErmesBookRepositoryImplementation();
  testErmesConnectionConcrete();
  testErmesDeduplication();
  testEncryptionDecryption();
  testErmesPeer();
  testErmesPeerRetransmissionIntegration();
  testErmesServiceRetransmission();
  testSerializationRegistry();
  await orchestration.main();
  // Note: testInitialPointSignaling() is already called by OrcErmes setup
  // so we skip it here to avoid duplication and state conflicts
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  // testErmesServiceImplementation(); // TODO: Fix after interface updates
}
