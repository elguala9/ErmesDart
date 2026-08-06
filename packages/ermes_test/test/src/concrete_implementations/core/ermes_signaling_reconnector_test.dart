import 'dart:convert';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Minimal real (non-framework-mock) handler whose [clearConnection] always
/// succeeds — the counterpart to `_TrackingHandler` in
/// `ermes_test_with_mock`'s reconnector test, which covers the
/// success/failure/max-attempts/resetAttempts paths already. This file
/// covers what that one does not: concurrent-attempt rejection and the
/// exponential backoff delay values themselves.
class _AlwaysClearsHandler implements IErmesSignalingHandler<IShspSocket> {
  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<List<IdAccountType>> getAllPeerIds() async => [];

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async =>
      throw UnimplementedError();

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
      throw UnimplementedError();

  @override
  Future<bool> isSocketReady(IdAccountType of) async => false;

  @override
  Future<SocketDto<IShspSocket>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> destroy() async {}
}

/// Real INostrSignaling that never has a signal available for
/// `retrieveLast`, so `ErmesSignalingServer.getSignal` always fails —
/// exactly the failure this reconnector needs to exercise its backoff.
class _NoSignalNostrSignaling implements INostrSignaling {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> destroy() async {}

  @override
  bool isConnected() => true;

  @override
  Future<String> publish(List<int> data) async => 'event-id';

  @override
  Future<String> subscribe(
    NostrUserId id,
    IEventCallback onEvent, {
    int? since,
  }) async =>
      'sub-id';

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => const [];

  @override
  Future<void> unsubscribe(NostrUserId id) async {}
}

SignalErmes _validSignal() => SignalErmes(
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '127.0.0.1',
      ipv4Port: '9999',
      epochTimestampStartConversation: 0,
      epochTimestampExpireConversation:
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    );

/// Real INostrSignaling that always has a signal available, so
/// `getSignal` always succeeds.
class _AlwaysSignalNostrSignaling extends _NoSignalNostrSignaling {
  @override
  Future<List<int>> retrieveLast(NostrUserId id) async =>
      utf8.encode(_validSignal().toString());
}

void testErmesSignalingReconnector() {
  group('ErmesSignalingReconnector — concurrency and backoff timing', () {
    test('rejects a concurrent reconnect attempt while one is already '
        'in progress', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _NoSignalNostrSignaling(),
        accountId: 'me',
      );
      final reconnector = ErmesSignalingReconnector(
        _AlwaysClearsHandler(),
        server,
        delay: (_) => Future<void>.delayed(const Duration(milliseconds: 300)),
      );

      final first = reconnector.reconnect('peer-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reconnector.isReconnecting, isTrue);

      await expectLater(
        reconnector.reconnect('peer-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Reconnection already in progress'),
          ),
        ),
      );

      await expectLater(first, throwsA(isA<Exception>()));
      await server.destroy();
    });

    test('a rejected concurrent attempt does not itself count towards '
        'reconnectAttempts', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _NoSignalNostrSignaling(),
        accountId: 'me',
      );
      final reconnector = ErmesSignalingReconnector(
        _AlwaysClearsHandler(),
        server,
        delay: (_) => Future<void>.delayed(const Duration(milliseconds: 300)),
      );

      final first = reconnector.reconnect('peer-1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final attemptsDuringFirst = reconnector.reconnectAttempts;

      await expectLater(reconnector.reconnect('peer-1'), throwsA(isA<Exception>()));
      expect(reconnector.reconnectAttempts, equals(attemptsDuringFirst));

      await expectLater(first, throwsA(isA<Exception>()));
      await server.destroy();
    });

    test('backoff delay is zero on the first attempt, then doubles on '
        'each successive failed attempt', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _NoSignalNostrSignaling(),
        accountId: 'me',
      );
      final recordedDelays = <Duration>[];
      final reconnector = ErmesSignalingReconnector(
        _AlwaysClearsHandler(),
        server,
        baseReconnectDelay: const Duration(milliseconds: 100),
        maxReconnectDelay: const Duration(seconds: 10),
        delay: (d) async => recordedDelays.add(d),
      );

      for (var i = 0; i < 3; i++) {
        await expectLater(
          reconnector.reconnect('peer-1'),
          throwsA(isA<Exception>()),
        );
      }

      expect(recordedDelays, [
        Duration.zero,
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 200),
      ]);
      await server.destroy();
    });

    test('backoff delay never exceeds maxReconnectDelay', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _NoSignalNostrSignaling(),
        accountId: 'me',
      );
      final recordedDelays = <Duration>[];
      final reconnector = ErmesSignalingReconnector(
        _AlwaysClearsHandler(),
        server,
        baseReconnectDelay: const Duration(milliseconds: 500),
        maxReconnectDelay: const Duration(milliseconds: 600),
        delay: (d) async => recordedDelays.add(d),
      );

      for (var i = 0; i < 3; i++) {
        await expectLater(
          reconnector.reconnect('peer-1'),
          throwsA(isA<Exception>()),
        );
      }

      // Uncapped 3rd-attempt delay would be 500*2=1000ms; must be capped.
      expect(recordedDelays.last, equals(const Duration(milliseconds: 600)));
      await server.destroy();
    });

    test('a successful reconnect resets attempts even after prior '
        'failures, and no further backoff delay is recorded beyond the '
        'attempt that succeeded', () async {
      final flakyServer = _FlakyThenWorkingServer();
      final reconnector = ErmesSignalingReconnector(
        _AlwaysClearsHandler(),
        flakyServer,
        delay: (_) async {},
      );

      await expectLater(
        reconnector.reconnect('peer-1'),
        throwsA(isA<Exception>()),
      );
      expect(reconnector.reconnectAttempts, equals(1));

      await reconnector.reconnect('peer-1');
      expect(reconnector.reconnectAttempts, equals(0));
    });
  });
}

/// Real IErmesSignalingServer wrapper whose first `getSignal` call fails
/// and every subsequent call succeeds — used to exercise the
/// fail-then-succeed reset path without any framework mock.
class _FlakyThenWorkingServer implements IErmesSignalingServer {
  final ErmesSignalingServer _inner = ErmesSignalingServer(
    nostrSignaling: _AlwaysSignalNostrSignaling(),
    accountId: 'me',
  );
  var _calls = 0;

  @override
  Future<SignalErmes> getSignal(IdAccountType from,
      {bool forceRefresh = false}) async {
    _calls++;
    if (_calls == 1) {
      throw Exception('forced first failure');
    }
    return _inner.getSignal(from, forceRefresh: forceRefresh);
  }

  @override
  Future<void> destroy() => _inner.destroy();

  @override
  Future<IdAccountType> getIdAccount() => _inner.getIdAccount();

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) =>
      _inner.setSignal(signal, to);

  @override
  void onSignal(void Function(ISignalErmes data) callback,
          [IdAccountType? from]) =>
      _inner.onSignal(callback, from);

  @override
  void onError(void Function(Object err) callback) =>
      _inner.onError(callback);

  @override
  void onClose(void Function() callback) => _inner.onClose(callback);

  @override
  Future<void> removeAllListeners() => _inner.removeAllListeners();

  @override
  Future<bool> isConnected() => _inner.isConnected();
}

void main() {
  testErmesSignalingReconnector();
}
