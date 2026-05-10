import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void testErmesHandshake() {
  group('ErmesAsyncHandshake', () {
    test('handshake() throws StateError before handshakeAsync()', () {
      final handshake = ErmesAsyncHandshake(
        (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
      );
      expect(
        () => handshake.handshake(),
        throwsA(isA<StateError>()),
      );
    });

    test('constructor stores local info', () {
      final input = (publicKey: 'pk', privateKey: 'sk', curve: 'ed25519');
      final handshake = ErmesAsyncHandshake(input);
      expect(handshake, isNotNull);
    });

    test('constructor accepts optional repository parameter', () {
      final handshake = ErmesAsyncHandshake(
        (publicKey: 'pk', privateKey: 'sk', curve: 'ed25519'),
      );
      expect(handshake, isNotNull);
    });
  });

  group('ErmesHandshakeHandler', () {
    test('constructor stores local info', () {
      final input = (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519');
      final handler = ErmesHandshakeHandler(input);
      expect(handler, isNotNull);
    });

    test('setLocalInfo updates local info', () {
      final handler = ErmesHandshakeHandler(
        (publicKey: 'old', privateKey: 'old', curve: 'ed25519'),
      );
      handler.setLocalInfo(
        (publicKey: 'newPub', privateKey: 'newPriv', curve: 'secp256k1'),
      );
      final handshake = handler.newHandshake(
        SignalErmes(
          publicKey: '',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 0,
        ),
      );
      expect(handshake, isA<ErmesAsyncHandshake>());
    });

    test('newHandshake creates ErmesAsyncHandshake with correct state', () {
      final handler = ErmesHandshakeHandler(
        (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
      );
      final handshake = handler.newHandshake(
        SignalErmes(
          publicKey: '',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 0,
        ),
      );
      expect(handshake, isA<ErmesAsyncHandshake>());
      expect(handshake.handshake, throwsA(isA<StateError>()));
    });
  });
}
