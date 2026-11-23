import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

SignalErmes _signal(
  String port, {
  int age = 0,
  int period = 60,
  String id = 'peer',
}) =>
    SignalErmes(
      idSignaling: id,
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '1.2.3.4',
      ipv4Port: port,
      epochTimestampStartConversation: _now() - age,
      epochTimestampExpireConversation: _now() - age + 600,
      secondsIntervalOpening: period,
    );

/// In-memory relay: serves the last signal stored per account.
class _MemoryRelay implements IErmesSignalingServer {
  final Map<IdAccountType, ISignalErmes> signals = {};

  @override
  Future<ISignalErmes> getSignal(IdAccountType from,
      {bool forceRefresh = false}) async {
    final s = signals[from];
    if (s == null) {
      throw Exception('no signal for $from');
    }
    return s;
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {}

  @override
  Future<IdAccountType> getIdAccount() async => 'me';

  @override
  Future<void> destroy() async {}

  @override
  void onSignal(void Function(ISignalErmes data) callback,
      [IdAccountType? from]) {}

  @override
  void onError(void Function(Object err) callback) {}

  @override
  void onClose(void Function() callback) {}

  @override
  Future<void> removeAllListeners() async {}

  @override
  Future<bool> isConnected() async => true;
}

/// Tests for [OrcPeerSignalWaiter]: signal filtering and republishing our
/// own signal while blocked on the peer.
void testOrcPeerSignalWaiter() {
  group('OrcPeerSignalWaiter', () {
    late _MemoryRelay relay;
    late int publishes;
    final ours = _signal('1000', period: 2, id: 'me');

    OrcPeerSignalWaiter waiter({int attempts = 3}) => OrcPeerSignalWaiter(
          relay,
          (_) async {
            publishes++;
            return ours;
          },
          maxAttempts: attempts,
          pollInterval: const Duration(milliseconds: 200),
        );

    setUp(() {
      relay = _MemoryRelay();
      publishes = 0;
    });

    test('returns a fresh peer signal', () async {
      relay.signals['peer'] = _signal('2000');
      final s = await waiter().wait('peer', ours);
      expect(s.ipv4Port, '2000');
    });

    test('rejects our own reflected signal and times out', () async {
      relay.signals['peer'] = _signal('1000', id: 'me');
      await expectLater(
        waiter().wait('peer', ours),
        throwsA(isA<CoreException>()),
      );
    });

    test('accepts a peer sharing our endpoint with a different id', () {
      expect(waiter().isUsable(_signal('1000'), ours), isTrue);
    });

    test('rejects our id even when the endpoint differs', () {
      expect(waiter().isUsable(_signal('3000', id: 'me'), ours), isFalse);
    });

    test('rejects a stale signal', () {
      final stale = _signal('2000', age: 200);
      expect(waiter().isUsable(stale, ours), isFalse);
      expect(waiter().isUsable(_signal('2000', age: 30), ours), isTrue);
    });

    test('wait records the accepted signal as last seen', () async {
      final w = waiter();
      relay.signals['peer'] = _signal('2000');
      final s = await w.wait('peer', ours);
      expect(w.lastSeen.isFresher('peer', s), isFalse);
      expect(w.lastSeen.isRegression('peer', s), isFalse);
    });

    test('rejects a signal older than the last seen one', () {
      final w = waiter()..accept('peer', _signal('2000', age: 10));
      final older = _signal('3000', age: 20);
      expect(w.isUsable(older, ours, peer: 'peer'), isFalse);
      // Without the counterpart the regression check does not apply.
      expect(w.isUsable(older, ours), isTrue);
    });

    test('accepts an equal or newer signal than the last seen one', () {
      final w = waiter()..accept('peer', _signal('2000', age: 10));
      expect(w.isUsable(_signal('2000', age: 10), ours, peer: 'peer'), isTrue);
      expect(w.isUsable(_signal('3000'), ours, peer: 'peer'), isTrue);
    });

    test('times out when only a regressed signal is served', () async {
      final w = waiter()..accept('peer', _signal('2000'));
      relay.signals['peer'] = _signal('3000', age: 20);
      await expectLater(
        w.wait('peer', ours),
        throwsA(isA<CoreException>()),
      );
    });

    test('last seen is independent per counterpart', () {
      final w = waiter()..accept('a', _signal('2000'));
      final older = _signal('3000', age: 20);
      expect(w.isUsable(older, ours, peer: 'b'), isTrue);
      expect(w.isUsable(older, ours, peer: 'a'), isFalse);
    });

    test('a shared store is honoured', () {
      final store = ErmesSignalLastSeenStoreFactory.create(
        const ErmesSignalLastSeenStoreInput(),
      )..record('peer', _signal('2000'));
      final w = OrcPeerSignalWaiter(relay, (_) async => ours, lastSeen: store);
      final older = _signal('3000', age: 20);
      expect(w.isUsable(older, ours, peer: 'peer'), isFalse);
    });

    test('rejects a signal starting in the future beyond the tolerance', () {
      const tol = OrcPeerSignalWaiter.clockSkewToleranceSeconds;
      final future = _signal('2000', age: -(tol + 60));
      expect(waiter().isUsable(future, ours), isFalse);
    });

    test('accepts a future start within the clock-skew tolerance', () {
      const tol = OrcPeerSignalWaiter.clockSkewToleranceSeconds;
      final skewed = _signal('2000', age: -(tol - 5));
      expect(waiter().isUsable(skewed, ours), isTrue);
    });

    test('republishes our signal while waiting for the peer', () async {
      final pending = waiter(attempts: 30).wait('peer', ours);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      relay.signals['peer'] = _signal('2000');
      final s = await pending;
      expect(s.ipv4Port, '2000');
      expect(publishes, greaterThanOrEqualTo(1));
    });
  });
}

void main() => testOrcPeerSignalWaiter();
