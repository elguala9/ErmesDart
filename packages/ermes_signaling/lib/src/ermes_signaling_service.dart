import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// 3️⃣ ErmesSignalingService - Servizio signaling
/// Tradotto da: ErmesSignalingService.ts
///
/// Responsabilità:
/// - Layer servizio sopra repository
/// - Delegazione metodi a repository

class ErmesSignalingService implements IErmesSignalingService {
  ErmesSignalingService(this._repo) {
    _repo.onSignal(_handleSignal);
  }
  final IErmesSignalingRepository<ISignalErmes> _repo;

  OnSignalCreateSocketCallback? signalCallback;

  @override
  Future<void> destroy() => _repo.destroy();

  @override
  Future<bool> isConnected() => _repo.isConnected();

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
      (await _repo.getSignal(from)).toString();

  @override
  Future<String> getIdAccount() => _repo.getIdAccount();

  @override
  Future<void> sendSignal(String to) => _repo.sendSignal(to);

  @override
  void removeAllListeners() => _repo.removeAllListeners();
}
