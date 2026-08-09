import 'dart:convert';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import '../../../../helpers/in_memory_signaling.dart';

/// A real (non-mock) [InMemoryNostrSignaling] that fails to unsubscribe a
/// specific peer, used to exercise the resilience of [unsubscribeAll].
class _FlakyUnsubscribeNostrSignaling extends InMemoryNostrSignaling {
  _FlakyUnsubscribeNostrSignaling(
    super._accountId,
    super._store,
    super._subscriptions,
    this._failingPeer,
  );

  final String _failingPeer;

  @override
  Future<void> unsubscribe(String id) async {
    if (id == _failingPeer) {
      throw Exception('relay unreachable');
    }
    await super.unsubscribe(id);
  }
}

// Anchored to the real clock: SignalErmes.isExpired() compares
// epochTimestampExpireConversation against DateTime.now(), so a synthetic
// small epoch (e.g. 100) would already read as expired and defeat the
// monotonic-cache logic under test.
final int _nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

SignalErmes _signalAt(int startOffsetSeconds) => SignalErmes(
      publicKey: 'pk',
      ipv6: '',
      ipv6Port: '',
      ipv4: '1.2.3.4',
      ipv4Port: '1000',
      epochTimestampStartConversation: _nowEpoch + startOffsetSeconds,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: _nowEpoch + startOffsetSeconds + 600,
    );

void testErmesSignalingServerSubscriptions() {
  group('ErmesSignalingServerSubscriptions', () {
    late Map<String, List<int>> store;
    late Map<String, List<InMemorySubscription>> subs;
    late ErmesSignalingServerListeners listeners;
    late ErmesSignalingServerSubscriptions subscriptions;

    setUp(() {
      store = {};
      subs = {};
      listeners = ErmesSignalingServerListeners();
      subscriptions = ErmesSignalingServerSubscriptions(
        nostrSignaling: InMemoryNostrSignaling('me', store, subs),
        listeners: listeners,
        maxDedupRecords: 10,
      );
    });

    group('subscribeToPeer', () {
      test('registers the peer as subscribed', () {
        subscriptions.subscribeToPeer('peer-a');
        expect(subscriptions.subscribedPeers, contains('peer-a'));
        expect(subscriptions.eventCallbacks.containsKey('peer-a'), isTrue);
      });

      test('is idempotent: a second call for the same peer does not '
          'create a duplicate subscription', () {
        subscriptions
          ..subscribeToPeer('peer-a')
          ..subscribeToPeer('peer-a');
        expect(subs['peer-a'], hasLength(1));
        expect(subscriptions.subscribedPeers, hasLength(1));
      });

      test('supports subscribing to multiple independent peers', () {
        subscriptions
          ..subscribeToPeer('peer-a')
          ..subscribeToPeer('peer-b');
        expect(
          subscriptions.subscribedPeers,
          unorderedEquals(['peer-a', 'peer-b']),
        );
      });
    });

    group('incoming event handling', () {
      test('a valid published signal is cached and forwarded to the '
          'sender-specific listener', () {
        ISignalErmes? received;
        listeners.onSignal((s) => received = s, 'peer-a');
        subscriptions.subscribeToPeer('peer-a');

        final signal = _signalAt(100);
        InMemoryNostrSignaling('peer-a', store, subs).publish(
          utf8.encode(signal.toString()),
        );

        expect(
          subscriptions
              .cachedSignals['peer-a']?.epochTimestampStartConversation,
          equals(_nowEpoch + 100),
        );
        expect(
          received?.epochTimestampStartConversation,
          equals(_nowEpoch + 100),
        );
      });

      test('malformed event payload is reported as an error and not '
          'cached', () {
        final errors = <Object>[];
        listeners.onError(errors.add);
        subscriptions.subscribeToPeer('peer-a');

        InMemoryNostrSignaling('peer-a', store, subs).publish(<int>[]);

        expect(errors, hasLength(1));
        expect(subscriptions.cachedSignals.containsKey('peer-a'), isFalse);
      });

      test('a newer signal (higher start timestamp) overwrites the cache',
          () {
        subscriptions.subscribeToPeer('peer-a');
        InMemoryNostrSignaling('peer-a', store, subs)
          ..publish(utf8.encode(_signalAt(100).toString()))
          ..publish(utf8.encode(_signalAt(150).toString()));

        expect(
          subscriptions
              .cachedSignals['peer-a']?.epochTimestampStartConversation,
          equals(_nowEpoch + 150),
        );
      });

      test('an older signal (lower start timestamp) never regresses the '
          'cache', () {
        subscriptions.subscribeToPeer('peer-a');
        InMemoryNostrSignaling('peer-a', store, subs)
          ..publish(utf8.encode(_signalAt(150).toString()))
          ..publish(utf8.encode(_signalAt(50).toString()));

        expect(
          subscriptions
              .cachedSignals['peer-a']?.epochTimestampStartConversation,
          equals(_nowEpoch + 150),
        );
      });

      test('an event for a peer with no registered listener is still '
          'cached but triggers no callback', () {
        subscriptions.subscribeToPeer('peer-a');
        InMemoryNostrSignaling('peer-a', store, subs)
            .publish(utf8.encode(_signalAt(100).toString()));
        expect(subscriptions.cachedSignals.containsKey('peer-a'), isTrue);
      });
    });

    group('unsubscribeAll', () {
      test('does nothing and does not throw when nothing is subscribed',
          () async {
        await expectLater(subscriptions.unsubscribeAll(), completes);
      });

      test('unsubscribes every previously subscribed peer', () async {
        subscriptions
          ..subscribeToPeer('peer-a')
          ..subscribeToPeer('peer-b');
        await subscriptions.unsubscribeAll();
        expect(subs['peer-a'], isNull);
        expect(subs['peer-b'], isNull);
      });

      test('swallows an exception from an individual unsubscribe call '
          'and still attempts the remaining peers', () async {
        final flaky = ErmesSignalingServerSubscriptions(
          nostrSignaling:
              _FlakyUnsubscribeNostrSignaling('me', store, subs, 'peer-a'),
          listeners: listeners,
          maxDedupRecords: 10,
        )
          ..subscribeToPeer('peer-a')
          ..subscribeToPeer('peer-b');

        await expectLater(flaky.unsubscribeAll(), completes);
        expect(subs['peer-b'], isNull);
      });
    });

    group('clear', () {
      test('removes cached signals, subscribed peers and event callbacks',
          () {
        subscriptions.subscribeToPeer('peer-a');
        InMemoryNostrSignaling('peer-a', store, subs)
            .publish(utf8.encode(_signalAt(100).toString()));

        subscriptions.clear();

        expect(subscriptions.cachedSignals, isEmpty);
        expect(subscriptions.subscribedPeers, isEmpty);
        expect(subscriptions.eventCallbacks, isEmpty);
      });

      test('is idempotent on an already-empty state', () {
        expect(subscriptions.clear, returnsNormally);
      });
    });
  });
}

void main() {
  testErmesSignalingServerSubscriptions();
}
