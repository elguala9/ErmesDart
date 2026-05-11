
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
  ErmesSignalingService(this.repo);

  ErmesSignalingService.emptyForDI();
  
  @isInjected
  late IErmesSignalingRepository<ISignalErmes> repo;
  @isOptionalParameter
  OnSignalCreateSocketCallback? signalCallback;

  @override
  Future<void> destroy() => repo.destroy();

  @override
  Future<bool> isConnected() => repo.isConnected();

  @override
  Future<ISignalErmes> getLastSignal() async {
    final signal = await repo.getLastSignal();
    if (signal == null) {
      throw Exception('No last signal available');
    }
    return signal;
  }

  @override
  Future<ISignalErmes> getLastSignalForced() async {
    final signal = await repo.getLastSignalForced();
    if (signal == null) {
      throw Exception('No last signal available');
    }
    return signal;
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
