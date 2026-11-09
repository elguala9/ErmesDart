import 'package:stun_shsp/stun_shsp.dart';

/// Makes [instance] respond to the peer's incoming handshake automatically
/// (SHSP protocol).
///
/// The response is sent only once to avoid feedback loops. A send failure
/// (e.g. a momentarily full socket buffer) is covered by the handshake
/// retransmission; letting it escape would surface as an unhandled error
/// from the socket receive path.
void registerHandshakeResponder(ShspInstance instance) {
  var handshakeResponseSent = false;
  instance.onHandshake.register((_) {
    if (!handshakeResponseSent) {
      handshakeResponseSent = true;
      try {
        instance.sendHandshake();
      } on ShspNetworkException {
        // Lost probe: the retransmission recovers.
      }
    }
  });
}
