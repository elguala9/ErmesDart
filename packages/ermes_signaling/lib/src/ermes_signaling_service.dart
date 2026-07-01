
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'exceptions.dart';

/// 3️⃣ ErmesSignalingService - Servizio signaling
/// Tradotto da: ErmesSignalingService.ts
///
/// Responsabilità:
/// - Layer servizio sopra repository
/// - Delegazione metodi a repository
@isSingleton
class ErmesSignalingService implements IErmesSignalingService {
  /// Creates a service delegating to the given signaling repository.
  ErmesSignalingService(this.repo);

  /// Creates an empty instance used by the dependency injection framework.
  ErmesSignalingService.emptyForDI();

  /// Repository the service delegates all signaling operations to.
  @isInjected
  late IErmesSignalingRepository<ISignalErmes> repo;

  /// Optional callback invoked when a signal triggers socket creation.
  @isOptionalParameter
  OnSignalCreateSocketCallback? signalCallback;

  /// Tears down the underlying repository.
  @override
  Future<void> destroy() => repo.destroy();

  /// Reports whether the signaling channel is connected.
  @override
  Future<bool> isConnected() => repo.isConnected();

  /// Returns the last received signal; throws if none is available.
  @override
  Future<ISignalErmes> getLastSignal() async {
    final signal = await repo.getLastSignal();
    if (signal == null) {
      throw SignalingException('No last signal available');
    }
    return signal;
  }

  /// Forces a refresh of the last signal; throws if none is available.
  @override
  Future<ISignalErmes> getLastSignalForced() async {
    final signal = await repo.getLastSignalForced();
    if (signal == null) {
      throw SignalingException('No last signal available');
    }
    return signal;
  }

  /// Registers the callback invoked when a signal creates a socket.
  @override
  void onSignal(OnSignalCreateSocketCallback callback) {
    signalCallback = callback;
  }

  /// Fetches the signal from the given sender as its string representation.
  Future<String> getSignal(String from) async =>
      (await repo.getSignal(from)).toString();

  /// Returns the local account identifier.
  @override
  Future<String> getIdAccount() => repo.getIdAccount();

  /// Sends the local signal to the given recipient.
  @override
  Future<void> sendSignal(String to) => repo.sendSignal(to);

  /// Removes all registered listeners.
  @override
  void removeAllListeners() => repo.removeAllListeners();
}
