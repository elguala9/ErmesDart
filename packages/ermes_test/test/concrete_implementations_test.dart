import 'src/concrete_implementations/cipher/cipher_factories_test.dart';
import 'src/concrete_implementations/cipher/ecdh_key_exchange_test.dart';
import 'src/concrete_implementations/cipher/ermes_peer_cipher_impl_test.dart';
import 'src/concrete_implementations/cipher/two_peer_cipher_exchange_test.dart';
import 'src/concrete_implementations/core/ermes_book_impl_test.dart';
import 'src/concrete_implementations/core/ermes_encryption_decryption_test.dart';
import 'src/concrete_implementations/core/ermes_peer_test.dart';
import 'src/concrete_implementations/core/ermes_service_retransmission_test.dart';
import 'src/concrete_implementations/orchestration/orchestration_tests.dart' as orchestration;

void main() {
  // Esegui test per le implementazioni concrete
  testErmesPeerCipherImplementation();
  testECDHKeyExchange();
  testCipherFactories();
  testTwoPeerCipherExchange();
  testErmesBookRepositoryImplementation();
  testEncryptionDecryption();
  testErmesPeer();
  testErmesServiceRetransmission();
  orchestration.main();
  // testErmesServiceImplementation(); // TODO: Fix after interface updates
}
