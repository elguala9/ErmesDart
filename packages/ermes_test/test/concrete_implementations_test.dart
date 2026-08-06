import 'src/concrete_implementations/cipher/cipher_factories_test.dart';
import 'src/concrete_implementations/cipher/ecdh_key_exchange_test.dart';
import 'src/concrete_implementations/cipher/ermes_cipher_exceptions_test.dart';
import 'src/concrete_implementations/cipher/ermes_peer_cipher_impl_test.dart';
import 'src/concrete_implementations/cipher/shared_secret_rekey_test.dart';
import 'src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart';
import 'src/concrete_implementations/core/connection_state_test.dart';
import 'src/concrete_implementations/core/ermes_book_impl_test.dart';
import 'src/concrete_implementations/core/ermes_book_service_gap.dart';
import 'src/concrete_implementations/core/ermes_connections_handler_test.dart';
import 'src/concrete_implementations/core/ermes_core_extended_test.dart';
import 'src/concrete_implementations/core/ermes_deduplication_test.dart';
import 'src/concrete_implementations/core/ermes_encryption_decryption_test.dart';
import 'src/concrete_implementations/core/ermes_factories_test.dart';
import 'src/concrete_implementations/core/ermes_handshake.dart';
import 'src/concrete_implementations/core/ermes_id_validator_test.dart';
import 'src/concrete_implementations/core/ermes_message_root_codec_test.dart';
import 'src/concrete_implementations/core/ermes_orc_full_flow_test.dart';
import 'src/concrete_implementations/core/ermes_orc_test.dart';
import 'src/concrete_implementations/core/ermes_peer_test.dart';
import 'src/concrete_implementations/core/orc_peer_info_from_signal_test.dart';
import 'src/concrete_implementations/core/ermes_redial_test.dart';
import 'src/concrete_implementations/core/ermes_service_features_test.dart';
import 'src/concrete_implementations/core/ermes_service_retransmission_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_factory.dart';
import 'src/concrete_implementations/core/ermes_signaling_handler_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_interfaces_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_reconnector_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_repository_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_server_listeners_test.dart';
import 'src/concrete_implementations/core/ermes_signaling_server_subscriptions_test.dart';
import 'src/concrete_implementations/core/ermes_utility_test.dart';
import 'src/concrete_implementations/core/fresh_socket_stun_test.dart';
import 'src/concrete_implementations/core/serialization_registry_test.dart';
import 'src/concrete_implementations/injection/injection_cipher_test.dart';
import 'src/concrete_implementations/injection/injection_id_handler_test.dart';
import 'src/concrete_implementations/injection/injection_message_control_test.dart';
import 'src/concrete_implementations/injection/injection_orc_ermes_test.dart';
import 'src/concrete_implementations/injection/injection_storage_test.dart';
import 'src/concrete_implementations/storage/storage_corruption_recovery_test.dart';
import 'src/concrete_implementations/storage/storage_encryption_at_rest_test.dart';
import 'src/concrete_implementations/storage/storage_persistence_test.dart';

Future<void> main() async {
  // Esegui test per le implementazioni concrete
  testErmesCipherExceptions();
  testErmesPeerCipherImplementation();
  testECDHKeyExchange();
  testCipherFactories();
  testTwoPeerCipherExchange();
  testSharedSecretRekey();
  testErmesBookRepositoryImplementation();
  testErmesDeduplication();
  testEncryptionDecryption();
  testErmesPeer();
  testErmesServiceRetransmission();
  testSerializationRegistry();

  // Validation
  testErmesIdValidator();

  // Message root build/decode codec (encryption, integrity, dedup)
  testErmesMessageRootCodec();

  // Peer info extraction from signaling data
  testPeerInfoFromSignal();

  // OrcErmes and Connections
  testOrcErmes();
  testOrcErmesFullFlow();
  testOrcErmesRedial();
  testOrcErmesSelfDial();
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

  // Signaling repository tests
  testErmesSignalingRepository();

  // Signaling reconnector, listeners, subscriptions, STUN discovery
  testErmesSignalingReconnector();
  testErmesSignalingServerListeners();
  testErmesSignalingServerSubscriptions();
  testFreshSocketStun();

  // Core extended tests (ErmesFactory, ShspSocket, OrcErmesAdvancedFactory)
  testErmesCoreExtended();

  // Service features (sendNewKey, sendAgain, listener management)
  testErmesServiceFeatures();

  // Storage: persistence, encryption at rest, corruption / recovery
  testStoragePersistence();
  testStorageEncryptionAtRest();
  testStorageCorruptionRecovery();

  // Dependency-injection tests
  testInjectionStorage();
  testInjectionMessageControl();
  await testInjectionCipher();
  testInjectionIdHandler();

  // OrcErmes composition-root tests
  testInjectionOrcErmes();
}
