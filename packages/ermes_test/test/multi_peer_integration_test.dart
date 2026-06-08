import 'src/multi_peer/cipher_exchange_tests.dart';
import 'src/multi_peer/disconnect_reconnect_tests.dart';
import 'src/multi_peer/multi_peer_scenarios.dart';
import 'src/multi_peer/n_peer_tests.dart';
import 'src/multi_peer/three_peer_tests.dart';
import 'src/multi_peer/two_peer_tests.dart';

void main() {
  runTwoPeerTests();
  runThreePeerTests();
  runNPeerTests();
  runMultiPeerScenarios();
  runCipherExchangeTests();
  runDisconnectReconnectTests();
}
