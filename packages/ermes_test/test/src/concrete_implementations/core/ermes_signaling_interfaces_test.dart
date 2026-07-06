import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void testErmesSignalingInterfaces() {
  testErmesSignalingServerSignalFlow();
  group('ISignalErmes contract (via SignalErmes)', () {
    SignalErmes createFullSignal() => SignalErmes(
          publicKey: 'test-pub-key',
          ipv6: '2001:db8::1',
          ipv6Port: '1234',
          ipv4: '192.168.1.1',
          ipv4Port: '5678',
          epochTimestampStartConversation: 1000,
          secondsIntervalWindow: 30,
          epochTimestampExpireConversation: 2000,
        );

    test('implements ISignalErmes', () {
      final signal = createFullSignal();
      expect(signal, isA<ISignalErmes>());
    });

    test('stores all fields correctly', () {
      final signal = createFullSignal();
      expect(signal.publicKey, equals('test-pub-key'));
      expect(signal.ipv6, equals('2001:db8::1'));
      expect(signal.ipv6Port, equals('1234'));
      expect(signal.ipv4, equals('192.168.1.1'));
      expect(signal.ipv4Port, equals('5678'));
      expect(signal.epochTimestampStartConversation, equals(1000));
      expect(signal.secondsIntervalWindow, equals(30));
      expect(signal.epochTimestampExpireConversation, equals(2000));
    });

    test('toString produces pipe-delimited format with 9 fields', () {
      final signal = createFullSignal();
      final str = signal.toString();
      final parts = str.split('|');
      expect(parts.length, equals(9));
      expect(parts[0], equals('test-pub-key'));
      expect(parts[1], equals('2001:db8::1'));
      expect(parts[2], equals('1234'));
      expect(parts[3], equals('192.168.1.1'));
      expect(parts[4], equals('5678'));
      expect(parts[5], equals('1000'));
      expect(parts[6], equals('30'));
      expect(parts[7], equals('2000'));
      // 9th field is the opening period; createFullSignal keeps the default.
      expect(parts[8], equals('60'));
    });

    test('fromString parses pipe-delimited format', () {
      final signal = SignalErmes.fromString(
        'pk|ipv6|port6|ipv4|port4|100|20|200',
      );
      expect(signal.publicKey, equals('pk'));
      expect(signal.ipv6, equals('ipv6'));
      expect(signal.ipv6Port, equals('port6'));
      expect(signal.ipv4, equals('ipv4'));
      expect(signal.ipv4Port, equals('port4'));
      expect(signal.epochTimestampStartConversation, equals(100));
      expect(signal.secondsIntervalWindow, equals(20));
      expect(signal.epochTimestampExpireConversation, equals(200));
    });

    test('toString and fromString are roundtrip compatible', () {
      final original = createFullSignal();
      final serialized = original.toString();
      final deserialized = SignalErmes.fromString(serialized);
      expect(deserialized.publicKey, equals(original.publicKey));
      expect(deserialized.ipv6, equals(original.ipv6));
      expect(deserialized.ipv6Port, equals(original.ipv6Port));
      expect(deserialized.ipv4, equals(original.ipv4));
      expect(deserialized.ipv4Port, equals(original.ipv4Port));
      expect(
        deserialized.epochTimestampStartConversation,
        equals(original.epochTimestampStartConversation),
      );
      expect(
        deserialized.secondsIntervalWindow,
        equals(original.secondsIntervalWindow),
      );
      expect(
        deserialized.epochTimestampExpireConversation,
        equals(original.epochTimestampExpireConversation),
      );
    });

    test('signal getter returns same as toString', () {
      final signal = createFullSignal();
      expect(signal.signal, equals(signal.toString()));
    });

    test('signal setter calls fromString', () {
      final signal = createFullSignal()
        ..signal = 'new-pk|v6|p6|v4|p4|100|20|200';
      expect(signal.publicKey, equals('new-pk'));
      expect(signal.ipv6, equals('v6'));
    });

    test('isExpired returns true for expired signal', () {
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
      expect(signal.isExpired(), isTrue);
    });

    test('isExpired returns false for future signal', () {
      final futureTime =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final signal = SignalErmes(
        publicKey: '',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: futureTime,
      );
      expect(signal.isExpired(), isFalse);
    });

    test('fromString throws ArgumentError for invalid format', () {
      expect(
        () => SignalErmes.fromString('invalid|format'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString throws ArgumentError for empty string', () {
      expect(
        () => SignalErmes.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ISignalErmesRaw contract (via SignalErmesRaw)', () {
    test('implements ISignalErmesRaw', () {
      final raw = SignalErmesRaw(
        signal: 'test-signal',
        isEncrypted: false,
      );
      expect(raw, isA<ISignalErmesRaw<dynamic>>());
    });

    test('stores fields correctly for unencrypted', () {
      final raw = SignalErmesRaw(
        signal: 'hello',
        isEncrypted: false,
      );
      expect(raw.signal, equals('hello'));
      expect(raw.isEncrypted, isFalse);
      expect(raw.encryptionType, isNull);
    });

    test('fromString parses unencrypted format', () {
      final raw = SignalErmesRaw(signal: '', isEncrypted: false)
        ..fromString('signal-data|false|');
      expect(raw.signal, equals('signal-data'));
      expect(raw.isEncrypted, isFalse);
    });

    test('toString produces pipe-delimited format', () {
      final raw = SignalErmesRaw(
        signal: 'my-signal',
        isEncrypted: false,
      );
      final str = raw.toString();
      expect(str, 'my-signal|false|null');
    });

    test('toString and fromString roundtrip', () {
      final raw = SignalErmesRaw(
        signal: 'roundtrip-signal',
        isEncrypted: false,
      );
      final serialized = raw.toString();
      final deserialized = SignalErmesRaw(signal: '', isEncrypted: false)
        ..fromString(serialized);
      expect(deserialized.signal, equals(raw.signal));
      expect(deserialized.isEncrypted, equals(raw.isEncrypted));
    });

    test('getSignal returns ISignalErmes', () {
      final raw = SignalErmesRaw(
        signal: 'test',
        isEncrypted: false,
      );
      final signal = raw.getSignal();
      expect(signal, isA<ISignalErmes>());
    });

    test('fromString parses encrypted format with encryption type', () {
      final raw = SignalErmesRaw(signal: '', isEncrypted: false)
        ..fromString('encrypted-signal|true|aes256');
      expect(raw.signal, equals('encrypted-signal'));
      expect(raw.isEncrypted, isTrue);
    });
  });

  group('IErmesSignalingServer contract (via ErmesSignalingServer)', () {
    test('implements IErmesSignalingServer', () {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test-account',
      );
      expect(server, isA<IErmesSignalingServer>());
    });

    test('getIdAccount returns accountId', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'my-account',
      );
      final id = await server.getIdAccount();
      expect(id, equals('my-account'));
    });

    test('isConnected returns false with disconnected Nostr', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      final connected = await server.isConnected();
      expect(connected, isFalse);
    });

    test('removeAllListeners clears callbacks', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      var errorCalled = false;
      server.onError((_) {
        errorCalled = true;
      });
      await server.removeAllListeners();
      expect(errorCalled, isFalse);
    });

    test('onError registers error callback', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      var errorCalled = false;
      server.onError((_) {
        errorCalled = true;
      });
      expect(errorCalled, isFalse);
    });

    test('onClose registers close callback', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      var closeCalled = false;
      server.onClose(() {
        closeCalled = true;
      });
      expect(closeCalled, isFalse);
    });

    test('destroy completes without error', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      await server.destroy();
    });

    test('destroy is idempotent', () async {
      final server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test',
      );
      await server.destroy();
      await server.destroy();
    });

    test('emptyForDI creates instance', () {
      final server = ErmesSignalingServer.emptyForDI();
      expect(server, isA<ErmesSignalingServer>());
    });
  });
}

class _DummyNostrSignaling extends INostrSignaling {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  bool isConnected() => false;

  @override
  Future<String> publish(List<int> data) async => 'dummy-event-id';

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async =>
      'dummy-sub-id';

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => [];

  @override
  Future<void> unsubscribe(NostrUserId id) async {}

  @override
  void destroy() {}

  void registerWith<T extends IValueForRegistry>() {}

  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

/// In-memory Nostr signaling for testing signal flow.
///
/// Stores published signals per account and delivers them via
/// [retrieveLast] and [subscribe] callbacks, enabling
/// end-to-end signal flow tests without an external relay.
class _InMemoryNostrSignaling extends INostrSignaling {
  _InMemoryNostrSignaling(
    this._accountId,
    this._store,
    this._subscriptions,
  );

  final String _accountId;
  final Map<String, List<int>> _store;
  final Map<String, List<_Subscription>> _subscriptions;

  @override
  bool isConnected() => true;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void destroy() {}

  @override
  Future<String> publish(List<int> data) async {
    _store[_accountId] = data;
    for (final entry in _subscriptions.entries) {
      if (entry.key == _accountId || entry.key == '*') {
        for (final sub in entry.value) {
          sub.onEvent('', data);
        }
      }
    }
    return 'mem-event-id';
  }

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async =>
      _store[id] ?? [];

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async {
    final key = id;
    _subscriptions.putIfAbsent(key, () => []);
    _subscriptions[key]!.add(_Subscription(id, onEvent));
    return 'mem-sub-id';
  }

  @override
  Future<void> unsubscribe(NostrUserId id) async {
    _subscriptions.remove(id);
  }

  void registerWith<T extends IValueForRegistry>() {}

  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

class _Subscription {
  _Subscription(this.peerId, this.onEvent);
  final String peerId;
  final IEventCallback onEvent;
}

/// Helper to create a test signal with specified fields and defaults for
/// the remaining required parameters.
ISignalErmes _testSignal({
  String publicKey = '',
  String ipv6 = '',
  String ipv6Port = '',
  String ipv4 = '',
  String ipv4Port = '',
  int epochTimestampStartConversation = 0,
  int secondsIntervalWindow = 0,
  int epochTimestampExpireConversation = 9999999999,
}) =>
    SignalErmes(
      publicKey: publicKey,
      ipv6: ipv6,
      ipv6Port: ipv6Port,
      ipv4: ipv4,
      ipv4Port: ipv4Port,
      epochTimestampStartConversation: epochTimestampStartConversation,
      secondsIntervalWindow: secondsIntervalWindow,
      epochTimestampExpireConversation: epochTimestampExpireConversation,
    );

void testErmesSignalingServerSignalFlow() {
  group('ErmesSignalingServer signal flow', () {
    test('onSignal callback invoked when matching signal is set', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      try {
        ISignalErmes? receivedSignal;
        server.onSignal((data) {
          receivedSignal = data;
        }, 'bob');

        final signal = _testSignal(
          publicKey: 'bob-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );

        final bob = ErmesSignalingServer(
          nostrSignaling: _InMemoryNostrSignaling('bob', store, subs),
          accountId: 'bob',
        );
        try {
          await bob.setSignal(signal, 'alice');
          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(receivedSignal, isNotNull);
          expect(receivedSignal!.publicKey, equals('bob-pk'));
          expect(receivedSignal!.ipv4, equals('10.0.0.1'));
        } finally {
          await bob.destroy();
        }
      } finally {
        await server.destroy();
      }
    });

    test('onSignal with null from receives locally set signals', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      try {
        final receivedSignals = <ISignalErmes>[];
        server.onSignal(receivedSignals.add);

        final signal = _testSignal(
          publicKey: 'local-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );

        await server.setSignal(signal, 'bob');
        // setSignal → _notifySignal(signal, 'bob') → null callback invoked

        expect(receivedSignals, hasLength(1));
        expect(receivedSignals.first.publicKey, equals('local-pk'));
      } finally {
        await server.destroy();
      }
    });

    test('getSignal with forceRefresh true fetches from Nostr', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      try {
        final signal = _testSignal(
          publicKey: 'bob-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );

        final bob = ErmesSignalingServer(
          nostrSignaling: _InMemoryNostrSignaling('bob', store, subs),
          accountId: 'bob',
        );
        try {
          await bob.setSignal(signal, 'alice');

          final retrieved = await server.getSignal('bob', forceRefresh: true);
          expect(retrieved.publicKey, equals('bob-pk'));
        } finally {
          await bob.destroy();
        }
      } finally {
        await server.destroy();
      }
    });

    test('publish and subscribe signal exchange between two servers',
        () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final alice = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      final bob = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('bob', store, subs),
        accountId: 'bob',
      );
      try {
        ISignalErmes? aliceReceived;
        alice.onSignal((data) {
          aliceReceived = data;
        }, 'bob');

        final bobSignal = _testSignal(
          publicKey: 'bob-pk',
          ipv4: '10.0.0.2',
          ipv4Port: '9001',
        );
        await bob.setSignal(bobSignal, 'alice');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(aliceReceived, isNotNull);
        expect(aliceReceived!.ipv4, equals('10.0.0.2'));

        ISignalErmes? bobReceived;
        bob.onSignal((data) {
          bobReceived = data;
        }, 'alice');

        final aliceSignal = _testSignal(
          publicKey: 'alice-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );
        await alice.setSignal(aliceSignal, 'bob');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(bobReceived, isNotNull);
        expect(bobReceived!.ipv4, equals('10.0.0.1'));
      } finally {
        await alice.destroy();
        await bob.destroy();
      }
    });

    test('getSignal caches and returns cached value without force', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      try {
        final signal = _testSignal(
          publicKey: 'bob-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );

        final bob = ErmesSignalingServer(
          nostrSignaling: _InMemoryNostrSignaling('bob', store, subs),
          accountId: 'bob',
        );
        try {
          await bob.setSignal(signal, 'alice');

          final refreshed = await server.getSignal('bob', forceRefresh: true);
          expect(refreshed.publicKey, equals('bob-pk'));

          final changedSignal = _testSignal(
            publicKey: 'bob-pk-changed',
            ipv4: '10.0.0.2',
            ipv4Port: '9002',
          );
          store['bob'] = [];
          await bob.setSignal(changedSignal, 'alice');

          final cached = await server.getSignal('bob');
          expect(cached.publicKey, equals('bob-pk'));

          final refetched = await server.getSignal('bob', forceRefresh: true);
          expect(refetched.publicKey, equals('bob-pk-changed'));
        } finally {
          await bob.destroy();
        }
      } finally {
        await server.destroy();
      }
    });

    test('onError callback invoked on signaling error', () async {
      final throwing = _ErrorOnRetrieveNostrSignaling();

      final server = ErmesSignalingServer(
        nostrSignaling: throwing,
        accountId: 'error-peer',
      );
      try {
        var errorCaught = false;
        server.onError((_) {
          errorCaught = true;
        });

        await expectLater(
          server.getSignal('unknown'),
          throwsA(isA<Exception>()),
        );

        expect(errorCaught, isTrue);
      } finally {
        await server.destroy();
      }
    });

    test('onClose callback invoked on destroy', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      var closeCalled = false;
      server.onClose(() {
        closeCalled = true;
      });
      expect(closeCalled, isFalse);
      await server.destroy();
      expect(closeCalled, isTrue);
    });

    test('destroy disconnects and clears server state', () async {
      final store = <String, List<int>>{};
      final subs = <String, List<_Subscription>>{};

      final server = ErmesSignalingServer(
        nostrSignaling: _InMemoryNostrSignaling('alice', store, subs),
        accountId: 'alice',
      );
      try {
        final signal = _testSignal(
          publicKey: 'bob-pk',
          ipv4: '10.0.0.1',
          ipv4Port: '9000',
        );

        final bob = ErmesSignalingServer(
          nostrSignaling: _InMemoryNostrSignaling('bob', store, subs),
          accountId: 'bob',
        );
        try {
          await bob.setSignal(signal, 'alice');
          final retrieved = await server.getSignal('bob', forceRefresh: true);
          expect(retrieved.publicKey, equals('bob-pk'));
        } finally {
          await bob.destroy();
        }

        await server.destroy();
        expect(await server.isConnected(), isTrue);
      } finally {
        await server.destroy();
      }
    });
  });
}

class _ErrorOnRetrieveNostrSignaling extends INostrSignaling {
  _ErrorOnRetrieveNostrSignaling();

  @override
  bool isConnected() => true;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void destroy() {}

  @override
  Future<String> publish(List<int> data) async => 'err-eid';

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async =>
      throw Exception('Nostr retrieval failed');

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async =>
      'err-sid';

  @override
  Future<void> unsubscribe(NostrUserId id) async {}

  void registerWith<T extends IValueForRegistry>() {}
  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

void main() {
  testErmesSignalingInterfaces();
}
