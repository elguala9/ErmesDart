import 'dart:convert';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

import '../../../../helpers/in_memory_signaling.dart';

const String _peer = 'peer-under-test';

/// A valid, unexpired 10-field signal whose conversation started at [start].
String _signalAt(int start, int port) =>
    'pk|||1.2.3.4|$port|$start|60|9999999999|10|$_peer';

/// Server backed by an in-memory relay; [relay] is the shared relay store.
ErmesSignalingServer _serverOn(Map<String, List<int>> relay) =>
    ErmesSignalingServer(
      nostrSignaling: InMemoryNostrSignaling(_peer, relay, {}),
      accountId: _peer,
    );

/// Puts [payload] on the relay and reads it once, so it lands in the cache.
Future<ErmesSignalingServer> _serverWithCached(
  Map<String, List<int>> relay,
  String payload,
) async {
  relay[_peer] = utf8.encode(payload);
  final server = _serverOn(relay);
  await server.getSignal(_peer, forceRefresh: true);
  return server;
}

void testErmesSignalingServerCacheFallback() {
  group('ErmesSignalingServer.getSignal relay/cache policy', () {
    test('default: relay empty -> returns the cached signal', () async {
      final relay = <String, List<int>>{};
      final server = await _serverWithCached(relay, _signalAt(1000, 5000));
      relay.remove(_peer);
      final s = await server.getSignal(_peer);
      expect(s.ipv4Port, '5000');
    });

    test('forceRefresh: relay empty -> throws, cache not served', () async {
      final relay = <String, List<int>>{};
      final server = await _serverWithCached(relay, _signalAt(1000, 5000));
      relay.remove(_peer);
      await expectLater(
        server.getSignal(_peer, forceRefresh: true),
        throwsA(isA<SignalingException>()),
      );
    });

    test('default: no relay signal and no cache -> throws', () async {
      final server = _serverOn(<String, List<int>>{});
      await expectLater(
        server.getSignal(_peer),
        throwsA(isA<SignalingException>()),
      );
    });

    test('default: relay newer than cache -> returns the relay one', () async {
      final relay = <String, List<int>>{};
      final server = await _serverWithCached(relay, _signalAt(1000, 5000));
      relay[_peer] = utf8.encode(_signalAt(2000, 6000));
      final s = await server.getSignal(_peer);
      expect(s.ipv4Port, '6000');
    });

    test('relay older than cache: default keeps the cache, forceRefresh '
        'returns the relay one', () async {
      final relay = <String, List<int>>{};
      final server = await _serverWithCached(relay, _signalAt(2000, 6000));
      relay[_peer] = utf8.encode(_signalAt(1000, 5000));
      expect((await server.getSignal(_peer)).ipv4Port, '6000');
      final forced = await server.getSignal(_peer, forceRefresh: true);
      expect(forced.ipv4Port, '5000');
    });
  });
}

void main() => testErmesSignalingServerCacheFallback();
