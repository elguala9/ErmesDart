import 'dart:convert';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:test/test.dart';

import '../../../../helpers/in_memory_signaling.dart';

const String _peer = 'peer-under-test';

/// A valid 10-field signal string (RFC section 6.1 wire format).
const String _validSignal =
    'pk|||1.2.3.4|5000|9999999999|60|9999999999|10|$_peer';

ErmesSignalingServer _serverWith(String payload) {
  final store = <String, List<int>>{_peer: utf8.encode(payload)};
  final nostr = InMemoryNostrSignaling(_peer, store, {});
  return ErmesSignalingServer(nostrSignaling: nostr, accountId: _peer);
}

void testErmesSignalingServerMalformed() {
  group('ErmesSignalingServer discards malformed relay signals', () {
    const legacy9 = 'pk|||1.2.3.4|5000|100|60|200|10';
    const legacy8 = 'pk|||1.2.3.4|5000|100|60|200';

    for (final entry in {
      'legacy 9-field signal': legacy9,
      'legacy 8-field signal': legacy8,
      '10 fields with empty idSignaling': '$legacy9|',
      'non-numeric timestamp': 'pk|||1.2.3.4|5000|abc|60|200|10|$_peer',
      'arbitrary garbage': 'not a signal',
    }.entries) {
      test('${entry.key} -> SignalingException, not an Error', () async {
        final server = _serverWith(entry.value);
        await expectLater(
          server.getSignal(_peer, forceRefresh: true),
          throwsA(isA<SignalingException>()),
        );
      });
    }

    test('a well-formed 10-field signal is still accepted', () async {
      final server = _serverWith(_validSignal);
      final signal = await server.getSignal(_peer, forceRefresh: true);
      expect(signal.idSignaling, _peer);
      expect(signal.secondsIntervalOpening, 10);
    });
  });
}

void main() => testErmesSignalingServerMalformed();
