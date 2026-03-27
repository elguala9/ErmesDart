
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// 3️⃣ ErmesSignalingService - Servizio signaling
/// Tradotto da: ErmesSignalingService.ts
///
/// Responsabilità:
/// - Layer servizio sopra repository
/// - Delegazione metodi a repository
@isSingleton
class ErmesSignalingService implements IErmesSignalingService {
  ErmesSignalingService(this.repo) {
    repo.onSignal(_handleSignal);
  }

  ErmesSignalingService.emptyForDI();
  
  @isInjected
  late IErmesSignalingRepository<ISignalErmes> repo;
  @isOptionalParameter
  OnSignalCreateSocketCallback? signalCallback;

  @override
  Future<void> destroy() => repo.destroy();

  @override
  Future<bool> isConnected() => repo.isConnected();

  void _handleSignal(ISignalErmes input) {
    // Qui puoi gestire il segnale ricevuto
    // input.peer contiene l'ID del peer
    // input.ermesService contiene il servizio Ermes

    // Esempio di implementazione base:
    // Puoi aggiungere la logica necessaria qui
  }

  @override
  void onSignal(OnSignalCreateSocketCallback callback) {
    signalCallback = callback;
  }

  Future<String> getSignal(String from) async =>
      (await repo.getSignal(from)).toString();

  @override
  Future<String> getIdAccount() => repo.getIdAccount();

  @override
  Future<void> sendSignal(String to) => repo.sendSignal(to);

  @override
  void removeAllListeners() => repo.removeAllListeners();
}
