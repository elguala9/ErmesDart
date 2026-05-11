import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

void testErmesSignalingInterfaces() {
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

    test('toString produces pipe-delimited format with 8 fields', () {
      final signal = createFullSignal();
      final str = signal.toString();
      final parts = str.split('|');
      expect(parts.length, equals(8));
      expect(parts[0], equals('test-pub-key'));
      expect(parts[1], equals('2001:db8::1'));
      expect(parts[2], equals('1234'));
      expect(parts[3], equals('192.168.1.1'));
      expect(parts[4], equals('5678'));
      expect(parts[5], equals('1000'));
      expect(parts[6], equals('30'));
      expect(parts[7], equals('2000'));
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

void main() {
  testErmesSignalingInterfaces();
}
