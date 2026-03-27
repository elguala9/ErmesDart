
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// 4️⃣ ErmesSignalingRepository - Repository signaling
/// Tradotto da: ErmesSignalingRepository.ts
///
/// Responsabilità:
/// - Coordinamento server/handler
/// - Gestione callback segnali
/// - Registrazione listener
@isSingleton
class ErmesSignalingRepository
    implements IErmesSignalingRepository<ISignalErmes> {

  ErmesSignalingRepository(this.signalingServer, this.signalHandler) {
    signalingServer.onSignal(_onSignalPrivate);
  }
  ErmesSignalingRepository.emptyForDI();

  
  @isInjected
  late IErmesSignalingServer signalingServer;
  @isInjected
  late IErmesSignalingHandler<IShspPeer> signalHandler;
  @isOptionalParameter
  OnSignalCallback<ISignalErmes>? onAnswerCallback;

  @override
  Future<bool> isConnected() => signalingServer.isConnected();

  @override
  Future<void> destroy() => signalingServer.destroy();

  @override
  Future<String> getIdAccount() => signalingServer.getIdAccount();

  @override
  Future<void> sendSignal(String to) async {
    final signal = await signalHandler.createSignal();
    await signalingServer.setSignal(signal, to);
  }

  @override
  Future<ISignalErmes> getSignal(String from) =>
      signalingServer.getSignal(from);

  @override
  Future<ISignalErmes> getSignalOwner() async {
    final signal = signalHandler.createSignal();
    return signal;
  }

  void _onSignalPrivate(ISignalErmes input) {
    if (onAnswerCallback == null) {
      return;
    }
    onAnswerCallback!(input);
  }

  @override
  void onSignal(OnSignalCallback<ISignalErmes> callback) {
    onAnswerCallback = callback;
  }

  @override
  bool compareSignalMessage(Object signal1, Object signal2) =>
      signal1.toString() == signal2.toString();

  @override
  void removeAllListeners() {
    signalingServer.removeAllListeners();
    onAnswerCallback = null;
  }
}
