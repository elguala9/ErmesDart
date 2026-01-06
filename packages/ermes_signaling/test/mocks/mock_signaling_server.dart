import 'package:ermes_signaling/src/ermes_signal_type.dart';
import 'package:iermes/iermes.dart';

/// Mock implementation of IErmesSignalingServer
///
/// Questo mock può essere facilmente sostituito con altre implementazioni
/// che implementano l'interfaccia IErmesSignalingServer.
///
/// Per sostituire il mock:
/// 1. Creare una nuova classe che implementa IErmesSignalingServer
/// 2. Sostituire MockSignalingServer() nei test con la nuova classe
/// 3. Tutti i test continueranno a funzionare senza modifiche
class MockSignalingServer implements IErmesSignalingServer {
  bool _connected = false;
  String _accountId = '';
  bool _shouldThrowError = false;

  // Call tracking
  bool destroyCalled = false;
  bool isConnectedCalled = false;
  bool getIdAccountCalled = false;
  bool setSignalCalled = false;
  bool getSignalCalled = false;
  bool onSignalCalled = false;
  bool removeAllListenersCalled = false;

  String lastSetSignalTarget = '';
  ISignalType? lastSetSignalValue;
  IdAccountType lastGetSignalFrom = '';
  final Map<IdAccountType, ISignalType> _signalsByPeer = {};

  void Function(ISignalType)? _signalCallback;

  // Metodi di configurazione per test
  void setConnected(bool connected) => _connected = connected;
  void setAccountId(String accountId) => _accountId = accountId;
  void setSignalForPeer(IdAccountType peerId, ISignalType signal) =>
      _signalsByPeer[peerId] = signal;
  void setShouldThrowError(bool shouldThrow) => _shouldThrowError = shouldThrow;

  // Getter pubblici per verifica nei test
  String get accountId => _accountId;
  bool get connected => _connected;

  // Metodi per simulare eventi
  void triggerSignalCallback(ISignalType signal) {
    _signalCallback?.call(signal);
  }

  @override
  Future<void> destroy() async {
    destroyCalled = true;
  }

  @override
  Future<bool> isConnected() async {
    isConnectedCalled = true;
    return _connected;
  }

  @override
  Future<String> getIdAccount() async {
    getIdAccountCalled = true;
    return _accountId;
  }

  @override
  Future<void> setSignal(ISignalType signal, [IdAccountType? to]) async {
    setSignalCalled = true;
    lastSetSignalValue = signal;
    if (to != null) {
      lastSetSignalTarget = to;
    }

    // Trigger callback if set
    _signalCallback?.call(signal);
  }

  @override
  Future<ISignalType> getSignal(IdAccountType from) async {
    if (_shouldThrowError) {
      throw Exception('Mock server error');
    }

    getSignalCalled = true;
    lastGetSignalFrom = from;
    return _signalsByPeer[from] ??
        SignalType.fromString(
          'default-key|::1|8080|127.0.0.1|8080|0|3600|${DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}',
        );
  }

  @override
  void onSignal(void Function(ISignalType) callback, [IdAccountType? from]) {
    onSignalCalled = true;
    _signalCallback = callback;
  }

  @override
  void onError(void Function(Object) callback) {
    // Mock implementation
  }

  @override
  void onClose(void Function() callback) {
    // Mock implementation
  }

  @override
  Future<void> removeAllListeners() async {
    removeAllListenersCalled = true;
    _signalCallback = null;
  }

  /// Factory method per creare istanze mock
  /// Facilita la sostituzione con altri mock implementando IErmesSignalingServer
  static IErmesSignalingServer createMock() => MockSignalingServer();
}
