
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'exceptions.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// 3️⃣ ErmesSignalingService - Servizio signaling
/// Tradotto da: ErmesSignalingService.ts
///
/// Responsabilità:
/// - Layer servizio sopra repository
/// - Delegazione metodi a repository
@dependencyInjectable
class ErmesSignalingService implements IErmesSignalingService {
  /// Creates a service delegating to the given signaling repository.
  ErmesSignalingService(this.repo);

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesSignalingService.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final repo = RegistryManager.instance.getInstance<IErmesSignalingRepository<ISignalErmes>>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingService( // GENERATED CODE - DO NOT MODIFY BY HAND
      repo, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Repository the service delegates all signaling operations to.
  final IErmesSignalingRepository<ISignalErmes> repo;

  /// Optional callback invoked when a signal triggers socket creation.
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
