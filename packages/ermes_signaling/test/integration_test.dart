
/*
/// Lightweight test doubles to satisfy interface tests without heavy deps
class _SimpleSignalingServer implements IErmesSignalingServer {
  bool _connected = true;
  final Map<String?, void Function(ISignalErmes)> _callbacks = {};

  @override
  Future<void> destroy() async {
    _connected = false;
    _callbacks.clear();
  }

  @override
  Future<IdAccountType> getIdAccount() async => 'test-account';

  @override
  Future<ISignalErmes> getSignal(IdAccountType from) async => _TestSignalErmes(
    publicKey: 'pk',
    ipv6: '::1',
    ipv6Port: '0',
    ipv4: '127.0.0.1',
    ipv4Port: '0',
    epochTimestampStartConversation:
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
    secondsIntervalWindow: 60,
    epochTimestampExpireConversation:
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60,
  );

  @override
  Future<bool> isConnected() async => _connected;

  @override
  void onClose(void Function() callback) {
    // ignore for tests
  }

  @override
  void onError(void Function(Object err) callback) {
    // ignore for tests
  }

  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {
    _callbacks[from] = callback;
  }

  @override
  Future<void> removeAllListeners() async {
    _callbacks.clear();
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    // Immediately notify callbacks to simulate delivery
    if (to != null && _callbacks.containsKey(to)) {
      _callbacks[to]?.call(signal);
    }
    if (_callbacks.containsKey(null)) {
      _callbacks[null]?.call(signal);
    }
  }
}

// Reuse the small test Signal from the test suite

  @override
  final int secondsIntervalWindow;

  @override
  final int epochTimestampExpireConversation;

  @override
  String toString() =>
      '$publicKey|$ipv6|$ipv6Port|$ipv4|$ipv4Port|'
      '$epochTimestampStartConversation|$secondsIntervalWindow|$epochTimestampExpireConversation';

  @override
  void fromString(String signalString) {
    throw UnimplementedError();
  }

  @override
  bool isExpired() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >
      epochTimestampExpireConversation;

  @override
  String get signal => toString();

  @override
  set signal(String value) => fromString(value);
}

void main() {
  runInterfaceTests(
    config: const InterfaceTestConfig(
      implementationName: 'ermes_signaling (test doubles)',
      groupName: 'ermes_signaling Interface Tests',
    ),
    factories: const InterfaceFactories(
      signalingServer: _SimpleSignalingServer.new,
    ),
  );
}
*/