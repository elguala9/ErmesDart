import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

/// 3️⃣ ErmesSignalingService - Servizio signaling
/// Tradotto da: ErmesSignalingService.ts
///
/// Responsabilità:
/// - Layer servizio sopra repository
/// - Delegazione metodi a repository
@includeInBarrelFile
class ErmesSignalingService implements IErmesSignalingService {
  ErmesSignalingService(this._repo);
  final IErmesSignalingRepository<dynamic> _repo;

  @override
  Future<void> destroy() => _repo.destroy();

  @override
  Future<bool> isConnected() => _repo.isConnected();

  @override
  Future<void> onSignal(OnSignalCreateSocketCallback callback) async {
    // TODO: Implementare la logica di socket creation quando viene ricevuto un segnale
    // Per ora questa è una placeholder che non fa nulla
    return Future<void>.value();
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
