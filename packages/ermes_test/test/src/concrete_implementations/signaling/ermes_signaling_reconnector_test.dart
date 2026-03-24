import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Minimal test helper implementations (no mock frameworks)
// ---------------------------------------------------------------------------

/// Minimal IErmesSignalingHandler that records clearConnection calls
class _TrackingHandler implements IErmesSignalingHandler<IShspSocket> {
  final List<String> clearedConnections = [];

  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {
    clearedConnections.add(remotePeerId);
  }

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<List<IdAccountType>> getAllPeerIds() async => [];

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async =>
      _dummySignal();

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<SocketDto<IShspSocket>> getSocket(IdAccountType of) async =>
      throw UnimplementedError('getSocket not needed in this test');

  @override
  Future<bool> isSocketReady(IdAccountType of) async => false;

  @override
  Future<SocketDto<IShspSocket>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async =>
      throw UnimplementedError('waitForConnect not needed in this test');

  @override
  Future<void> destroy() async {}
}

/// Minimal IErmesSignalingServer that returns a dummy signal
class _DummySignalingServer implements IErmesSignalingServer {
  @override
  Future<ISignalErmes> getSignal(IdAccountType from) async => _dummySignal();

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {}

  @override
  Future<IdAccountType> getIdAccount() async => 'test-account';

  @override
  Future<void> destroy() async {}

  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {}

  @override
  void onError(void Function(Object err) callback) {}

  @override
  void onClose(void Function() callback) {}

  @override
  Future<void> removeAllListeners() async {}

  @override
  Future<bool> isConnected() async => true;
}

SignalErmes _dummySignal() => SignalErmes(
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '127.0.0.1',
      ipv4Port: '9999',
      epochTimestampStartConversation: 0,
      epochTimestampExpireConversation:
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ErmesSignalingReconnector', () {
    late _TrackingHandler handler;
    late _DummySignalingServer server;
    late ErmesSignalingReconnector reconnector;

    setUp(() {
      handler = _TrackingHandler();
      server = _DummySignalingServer();
      reconnector = ErmesSignalingReconnector(handler, server);
    });

    group('initial state', () {
      test('isReconnecting is false at construction', () {
        expect(reconnector.isReconnecting, isFalse);
      });

      test('reconnectAttempts is 0 at construction', () {
        expect(reconnector.reconnectAttempts, equals(0));
      });
    });

    group('reconnect', () {
      test('increments reconnectAttempts after each successful call', () async {
        await reconnector.reconnect('peer-1');
        expect(reconnector.reconnectAttempts, equals(1));

        await reconnector.reconnect('peer-1');
        expect(reconnector.reconnectAttempts, equals(2));
      });

      test('isReconnecting is false after reconnect completes', () async {
        await reconnector.reconnect('peer-1');
        expect(reconnector.isReconnecting, isFalse);
      });

      test('calls clearConnection on the handler', () async {
        await reconnector.reconnect('peer-abc');
        expect(handler.clearedConnections, contains('peer-abc'));
      });

      test('throws when max attempts (3) exceeded', () async {
        await reconnector.reconnect('peer-1');
        await reconnector.reconnect('peer-1');
        await reconnector.reconnect('peer-1');

        expect(
          () => reconnector.reconnect('peer-1'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Maximum reconnection attempts exceeded'),
            ),
          ),
        );
      });
    });

    group('resetAttempts', () {
      test('resets reconnectAttempts to 0', () async {
        await reconnector.reconnect('peer-1');
        await reconnector.reconnect('peer-1');
        reconnector.resetAttempts();
        expect(reconnector.reconnectAttempts, equals(0));
      });

      test('allows reconnect after reaching max attempts and resetting',
          () async {
        await reconnector.reconnect('peer-1');
        await reconnector.reconnect('peer-1');
        await reconnector.reconnect('peer-1');

        reconnector.resetAttempts();

        // Should succeed without throwing
        await reconnector.reconnect('peer-1');
        expect(reconnector.reconnectAttempts, equals(1));
      });
    });
  });
}
