
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

  ISignalErmes? _lastSignal;

  @override
  Future<void> destroy() => repo.destroy();

  @override
  Future<bool> isConnected() => repo.isConnected();

  @override
  Future<ISignalErmes?> getLastSignal() async => _lastSignal;

  void _handleSignal(ISignalErmes input) {
    _lastSignal = input;
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
