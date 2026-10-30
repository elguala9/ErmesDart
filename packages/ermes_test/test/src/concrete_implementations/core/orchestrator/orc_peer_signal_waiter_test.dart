import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

SignalErmes _signal(String port, {int age = 0, int period = 60}) =>
    SignalErmes(
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
    final ours = _signal('1000', period: 2);

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
      relay.signals['peer'] = _signal('1000');
      await expectLater(
        waiter().wait('peer', ours),
        throwsA(isA<CoreException>()),
      );
    });

    test('rejects a stale signal', () {
      final stale = _signal('2000', age: 200);
      expect(waiter().isUsable(stale, ours), isFalse);
      expect(waiter().isUsable(_signal('2000', age: 30), ours), isTrue);
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
