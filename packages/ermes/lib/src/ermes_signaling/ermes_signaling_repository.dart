import 'package:iermes/iermes.dart';

/// 4️⃣ ErmesSignalingRepository - Repository signaling
/// Tradotto da: ErmesSignalingRepository.ts
///
/// Responsabilità:
/// - Coordinamento server/handler
/// - Gestione callback segnali
/// - Registrazione listener
class ErmesSignalingRepository implements IErmesSignalingRepository<String> {
  ErmesSignalingRepository(this._signalingServer, this._signalHandler) {
    _signalingServer.onSignal(_onSignalPrivate);
  }
  final IErmesSignalingServer _signalingServer;
  final IErmesSignalingHandler<dynamic> _signalHandler;
  OnSignalCallback<String>? _onAnswerCallback;

  @override
  Future<bool> isConnected() => _signalingServer.isConnected();

  @override
  Future<void> destroy() => _signalingServer.destroy();

  @override
  Future<String> getIdAccount() => _signalingServer.getIdAccount();

  @override
  Future<void> sendSignal(String to) async {
    final signal = await _signalHandler.createSignal();
    await _signalingServer.setSignal(to, signal);
  }

  @override
  Future<String> getSignal(String from) => _signalingServer.getSignal(from);

  @override
  Future<String> getSignalOwner() => _signalHandler.createSignal();

  Future<void> _onSignalPrivate(String input) async {
    if (_onAnswerCallback == null) return;
    _onAnswerCallback!(input);
  }

  @override
  Future<void> onSignal(OnSignalCallback<String> callback) async {
    _onAnswerCallback = callback;
  }

  @override
  bool compareSignalMessage(dynamic signal1, dynamic signal2) =>
      signal1.toString() == signal2.toString();

  @override
  void removeAllListeners() {
    _signalingServer.removeAllListeners();
    _onAnswerCallback = null;
  }
}
