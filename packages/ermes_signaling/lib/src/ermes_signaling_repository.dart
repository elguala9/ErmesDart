
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

/// 4️⃣ ErmesSignalingRepository - Repository signaling
/// Tradotto da: ErmesSignalingRepository.ts
///
/// Responsabilità:
/// - Coordinamento server/handler
/// - Gestione callback segnali
/// - Registrazione listener

class ErmesSignalingRepository
    implements IErmesSignalingRepository<ISignalErmes> {
  ErmesSignalingRepository(this._signalingServer, this._signalHandler) {
    _signalingServer.onSignal(_onSignalPrivate);
  }
  final IErmesSignalingServer _signalingServer;
  final IErmesSignalingHandler<IShspPeer> _signalHandler;
  OnSignalCallback<ISignalErmes>? _onAnswerCallback;

  @override
  Future<bool> isConnected() => _signalingServer.isConnected();

  @override
  Future<void> destroy() => _signalingServer.destroy();

  @override
  Future<String> getIdAccount() => _signalingServer.getIdAccount();

  @override
  Future<void> sendSignal(String to) async {
    final signal = await _signalHandler.createSignal();
    await _signalingServer.setSignal(signal, to);
  }

  @override
  Future<ISignalErmes> getSignal(String from) =>
      _signalingServer.getSignal(from);

  @override
  Future<ISignalErmes> getSignalOwner() async {
    final signal = _signalHandler.createSignal();
    return signal;
  }

  void _onSignalPrivate(ISignalErmes input) {
    if (_onAnswerCallback == null) {
      return;
    }
    _onAnswerCallback!(input);
  }

  @override
  void onSignal(OnSignalCallback<ISignalErmes> callback) {
    _onAnswerCallback = callback;
  }

  @override
  bool compareSignalMessage(Object signal1, Object signal2) =>
      signal1.toString() == signal2.toString();

  @override
  void removeAllListeners() {
    _signalingServer.removeAllListeners();
    _onAnswerCallback = null;
  }
}
