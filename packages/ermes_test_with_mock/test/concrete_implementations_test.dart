import 'src/concrete_implementations/core/ermes_connection_test.dart';
import 'src/concrete_implementations/core/ermes_peer_retransmission_integration_test.dart';
import 'src/concrete_implementations/signaling/mock_signaling_server_test.dart';

void main() {
  testErmesConnectionConcrete();
  testErmesPeerRetransmissionIntegration();
  testMockSignalingServer();
}
