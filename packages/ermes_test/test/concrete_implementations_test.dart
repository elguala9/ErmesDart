import 'src/concrete_implementations/cipher/cipher_factories_test.dart';
import 'src/concrete_implementations/cipher/ecdh_key_exchange_test.dart';
import 'src/concrete_implementations/cipher/ermes_cipher_exceptions_test.dart';
import 'src/concrete_implementations/cipher/ermes_peer_cipher_impl_test.dart';
import 'src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart';
import 'src/concrete_implementations/core/connection_state_test.dart';
import 'src/concrete_implementations/core/ermes_book_impl_test.dart';
import 'src/concrete_implementations/core/ermes_connections_handler_test.dart';
import 'src/concrete_implementations/core/ermes_deduplication_test.dart';
import 'src/concrete_implementations/core/ermes_encryption_decryption_test.dart';
import 'src/concrete_implementations/core/ermes_factories_test.dart';
import 'src/concrete_implementations/core/ermes_orc_test.dart';
import 'src/concrete_implementations/core/ermes_orc_full_flow_test.dart';
import 'src/concrete_implementations/core/ermes_peer_test.dart';
import 'src/concrete_implementations/core/ermes_service_retransmission_test.dart';
import 'src/concrete_implementations/core/ermes_utility_test.dart';
import 'src/concrete_implementations/core/serialization_registry_test.dart';
import 'src/concrete_implementations/core/ermes_handshake.dart';
import 'src/concrete_implementations/core/ermes_signaling_factory.dart';
import 'src/concrete_implementations/core/ermes_book_service_gap.dart';
import 'src/concrete_implementations/core/ermes_signaling_handler_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_interfaces_test.dart';
import 'src/concrete_implementations/core/ermes_core_extended_test.dart';
import 'src/concrete_implementations/core/ermes_service_features_test.dart';
import 'src/concrete_implementations/initial_point/initial_point_integration_test.dart';
import 'src/concrete_implementations/initial_point/initial_point_ermes_core_test.dart';

Future<void> main() async {
  // Esegui test per le implementazioni concrete
  testErmesCipherExceptions();
  testErmesPeerCipherImplementation();
  testECDHKeyExchange();
  testCipherFactories();
  testTwoPeerCipherExchange();
  testErmesBookRepositoryImplementation();
  testErmesDeduplication();
  testEncryptionDecryption();
  testErmesPeer();
  testErmesServiceRetransmission();
  testSerializationRegistry();

  // OrcErmes and Connections
  testOrcErmes();
  testOrcErmesFullFlow();
  testErmesConnectionsHandler();

  // Utility tests
  testObservableQueue();
  testChunkHandler();
  testComposeUint8Array();
  testGetMissingIndices();
  testHashUtils();
  testUtilityFunctions();

  // Model tests
  testConnectionState();

  // Factory tests
  testErmesFactories();

  // Handshake tests
  testErmesHandshake();

  // Signaling factory tests
  testErmesSignalingFactories();

  // Book service gap tests
  testErmesBookServiceGaps();

  // Signaling handler tests
  testErmesSignalingHandler();

  // Signaling interfaces contract tests
  testErmesSignalingInterfaces();

  // Core extended tests (ErmesFactory, ShspSocket, OrcErmesAdvancedFactory)
  testErmesCoreExtended();

  // Service features (sendNewKey, sendAgain, listener management)
  testErmesServiceFeatures();

  // Run initial point DI tests
  testInitialPointStorage();
  testInitialPointMessageControl();
  testInitialPointCipher();
  testInitialPointIdHandler();
  testInitialPointStorageRegistry();
  testInitialPointMessageControlRegistry();
  await testInitialPointCipherRegistry();
  testInitialPointIdHandlerRegistry();

  // Initial point core/signaling tests
  testInitialPointErmesCore();
}
