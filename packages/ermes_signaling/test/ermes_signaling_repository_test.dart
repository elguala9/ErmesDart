
import 'dart:async';
import 'dart:convert';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Builds a real signaling handler over [stunShspHandler].
///
/// These tests only exercise the repository's signal bookkeeping, but the
/// handler is a required collaborator, so it gets a genuine one rather than a
/// stand-in.
ErmesSignalingHandler _handlerFor(StunShspHandler stunShspHandler) =>
    ErmesSignalingHandler(
      stunShspHandler,
      stunShspHandler,
      ErmesBookServiceBase(ErmesBookRepository()),
    );

void main() {
  group('ErmesSignalingRepository.getLastSignal', () {
    late ErmesSignalingServer server;
    late ErmesSignalingRepository repository;

    late StunShspHandler stunShspHandler;

    setUp(() async {
      stunShspHandler = await StunShspHandler.createDefault(ipv6: false);
      server = ErmesSignalingServer(
        nostrSignaling: _DummyNostrSignaling(),
        accountId: 'test-account',
      );
      repository = ErmesSignalingRepository(
        server,
        _handlerFor(stunShspHandler),
      );
    });

    tearDown(() async {
      await server.destroy();
      stunShspHandler.close();
    });

    test('returns null when no signal received', () async {
      final lastSignal = await repository.getLastSignal();
      expect(lastSignal, isNull);
    });

    test('returns signal after setSignal notifies callback', () async {
      final signal = SignalErmes(
        publicKey: 'sender-pubkey',
        ipv6: '',
        ipv6Port: '',
        ipv4: '192.168.1.1',
        ipv4Port: '9000',
        epochTimestampStartConversation: 1000,
        epochTimestampExpireConversation: 2000,
      );

      await server.setSignal(signal, 'peer-id');

      final lastSignal = await repository.getLastSignal();
      expect(lastSignal, isA<ISignalErmes>());
      expect(lastSignal!.publicKey, equals('sender-pubkey'));
    });

    test('returns most recent signal after multiple signals', () async {
      final signal1 = SignalErmes(
        publicKey: 'first',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: 1000,
      );
      final signal2 = SignalErmes(
        publicKey: 'last',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: 2000,
      );

      await server.setSignal(signal1, 'peer-1');
      await server.setSignal(signal2, 'peer-2');

      final lastSignal = await repository.getLastSignal();
      expect(lastSignal!.publicKey, equals('last'));
    });

    test('still returns signal after removeAllListeners', () async {
      final signal = SignalErmes(
        publicKey: 'persistent',
        ipv6: '',
        ipv6Port: '',
        ipv4: '',
        ipv4Port: '',
        epochTimestampStartConversation: 0,
        secondsIntervalWindow: 0,
        epochTimestampExpireConversation: 1000,
      );

      await server.setSignal(signal, 'peer-id');

        repository.removeAllListeners();

      final lastSignal = await repository.getLastSignal();
      expect(lastSignal!.publicKey, equals('persistent'));
    });
  });

  group('ErmesSignalingRepository.getLastSignalForced', () {
    late _ControllableNostrSignaling nostr;
    late ErmesSignalingServer server;
    late ErmesSignalingRepository repository;

    late StunShspHandler stunShspHandler;

    setUp(() async {
      stunShspHandler = await StunShspHandler.createDefault(ipv6: false);
      nostr = _ControllableNostrSignaling();
      server = ErmesSignalingServer(
        nostrSignaling: nostr,
        accountId: 'test-account',
      );
      repository = ErmesSignalingRepository(
        server,
        _handlerFor(stunShspHandler),
      );
    });

    tearDown(() async {
      await server.destroy();
      stunShspHandler.close();
    });

    test('returns null when no signal received', () async {
      final result = await repository.getLastSignalForced();
      expect(result, isNull);
    });

    test('returns cached signal when relay returns nothing', () async {
      final signal = SignalErmes(
        publicKey: 'cached-pubkey',
        ipv6: '',
        ipv6Port: '',
        ipv4: '10.0.0.1',
        ipv4Port: '8000',
        epochTimestampStartConversation: 100,
        epochTimestampExpireConversation: 2000,
      );
      await server.setSignal(signal, 'peer-id');

      nostr.retrieveResult = [];

      final result = await repository.getLastSignalForced();
      expect(result, isNotNull);
      expect(result!.publicKey, equals('cached-pubkey'));
    });

    test('returns fresh signal from relay after force refresh', () async {
      final signal = SignalErmes(
        publicKey: 'old-pubkey',
        ipv6: '',
        ipv6Port: '',
        ipv4: '10.0.0.1',
        ipv4Port: '8000',
        epochTimestampStartConversation: 100,
        epochTimestampExpireConversation: 2000,
      );
      await server.setSignal(signal, 'peer-id');

      final freshSignal = SignalErmes(
        publicKey: 'old-pubkey',
        ipv6: '',
        ipv6Port: '',
        ipv4: '10.0.0.2',
        ipv4Port: '9000',
        epochTimestampStartConversation: 200,
        secondsIntervalWindow: 20,
        epochTimestampExpireConversation: 3000,
      );
      final bytes = utf8.encode(freshSignal.toString());
      nostr.retrieveResult = bytes;

      final result = await repository.getLastSignalForced();
      expect(result, isNotNull);
      expect(result!.ipv4, equals('10.0.0.2'));
      expect(result.ipv4Port, equals('9000'));
      expect(result.epochTimestampStartConversation, equals(200));
    });
  });
}

class _ControllableNostrSignaling extends _DummyNostrSignaling {
  List<int> retrieveResult = [];

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => retrieveResult;
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
  Future<void> destroy() async {}

}
