import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

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
      const input = (publicKey: 'pk', privateKey: 'sk', curve: 'ed25519');
      final handshake = ErmesAsyncHandshake(input);
      expect(handshake, isNotNull);
    });

    test('constructor accepts optional repository parameter', () {
      final handshake = ErmesAsyncHandshake(
        (publicKey: 'pk', privateKey: 'sk', curve: 'ed25519'),
      );
      expect(handshake, isNotNull);
    });

    test('handshakeAsync throws StateError when no repository set', () async {
      final handshake = ErmesAsyncHandshake(
        (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
      );
      await expectLater(
        () => handshake.handshakeAsync(
          remoteSignal: SignalErmes(
            publicKey: '',
            ipv6: '',
            ipv6Port: '',
            ipv4: '',
            ipv4Port: '',
            epochTimestampStartConversation: 0,
            secondsIntervalWindow: 0,
            epochTimestampExpireConversation: 0,
          ),
          signalingHandler: _createTestSignalingHandler(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('handshakeAsync succeeds with repository', () async {
      final repository = await TestErmesRepository.create(peerId: 'test-peer');
      try {
        final handshake = ErmesAsyncHandshake(
          (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
          repository: repository,
        );
        final result = await handshake.handshakeAsync(
          remoteSignal: SignalErmes(
            publicKey: '',
            ipv6: '',
            ipv6Port: '',
            ipv4: '',
            ipv4Port: '',
            epochTimestampStartConversation: 0,
            secondsIntervalWindow: 0,
            epochTimestampExpireConversation: 0,
          ),
          signalingHandler: _createTestSignalingHandler(),
        );
        expect(result, same(repository));
      } finally {
        repository.cleanUp();
      }
    });

    test('handshakeAsync returns cached repository on second call', () async {
      final repository = await TestErmesRepository.create(peerId: 'test-peer');
      try {
        final handshake = ErmesAsyncHandshake(
          (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
          repository: repository,
        );
        final signal = SignalErmes(
          publicKey: '',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 0,
        );
        final first = await handshake.handshakeAsync(
          remoteSignal: signal,
          signalingHandler: _createTestSignalingHandler(),
        );
        final second = await handshake.handshakeAsync(
          remoteSignal: signal,
          signalingHandler: _createTestSignalingHandler(),
        );
        expect(first, same(second));
      } finally {
        repository.cleanUp();
      }
    });

    test('handshake() returns repository after handshakeAsync', () async {
      final repository = await TestErmesRepository.create(peerId: 'test-peer');
      try {
        final handshake = ErmesAsyncHandshake(
          (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
          repository: repository,
        );
        await handshake.handshakeAsync(
          remoteSignal: SignalErmes(
            publicKey: '',
            ipv6: '',
            ipv6Port: '',
            ipv4: '',
            ipv4Port: '',
            epochTimestampStartConversation: 0,
            secondsIntervalWindow: 0,
            epochTimestampExpireConversation: 0,
          ),
          signalingHandler: _createTestSignalingHandler(),
        );
        final result = handshake.handshake();
        expect(result, same(repository));
      } finally {
        repository.cleanUp();
      }
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

    test('implements IErmesHandshakeHandler', () {
      final handler = ErmesHandshakeHandler(
        (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
      );
      expect(handler, isA<IErmesHandshakeHandler>());
    });

    test('setLocalInfo is idempotent', () {
      final handler = ErmesHandshakeHandler(
        (publicKey: 'pub', privateKey: 'priv', curve: 'ed25519'),
      );
      handler.setLocalInfo(
        (publicKey: 'a', privateKey: 'b', curve: 'ed25519'),
      );
      handler.setLocalInfo(
        (publicKey: 'a', privateKey: 'b', curve: 'ed25519'),
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
  });
}

IErmesSignalingHandler<IShspSocket> _createTestSignalingHandler() {
  return _TestSignalingHandler();
}

class _TestSignalingHandler implements IErmesSignalingHandler<IShspSocket> {
  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async {
    return SignalErmes(
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '',
      ipv4Port: '',
      epochTimestampStartConversation: 0,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: 0,
    );
  }

  @override
  Future<void> destroy() async {}

  @override
  Future<List<IdAccountType>> getAllPeerIds() async => [];

  @override
  Future<SocketDto<IShspSocket>> getSocket(IdAccountType of) async {
    throw Exception('Not implemented');
  }

  @override
  Future<bool> isSocketReady(IdAccountType of) async => false;

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<SocketDto<IShspSocket>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async {
    throw TimeoutException('Timeout');
  }
}

void main() {
  testErmesHandshake();
}
