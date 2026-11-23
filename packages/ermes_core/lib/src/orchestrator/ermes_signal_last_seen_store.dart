import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// In-memory [IErmesSignalLastSeenStore]. One instance per registry key, so
/// co-hosted peers never share last-seen state.
@dependencyInjectable
class ErmesSignalLastSeenStore implements IErmesSignalLastSeenStore {
  /// Creates an empty store.
  ErmesSignalLastSeenStore();

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory ErmesSignalLastSeenStore.dependencyInjectionFactory({
    // ignore: avoid_unused_constructor_parameters
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) => ErmesSignalLastSeenStore(); // GENERATED CODE - DO NOT MODIFY BY HAND

  final Map<IdPeer, int> _lastStart = {};

  @override
  bool isRegression(IdPeer peer, ISignalErmes signal) {
    final last = _lastStart[peer];
    return last != null && signal.epochTimestampStartConversation < last;
  }

  @override
  bool isFresher(IdPeer peer, ISignalErmes signal) {
    final last = _lastStart[peer];
    return last == null || signal.epochTimestampStartConversation > last;
  }

  @override
  void record(IdPeer peer, ISignalErmes signal) {
    if (isFresher(peer, signal)) {
      _lastStart[peer] = signal.epochTimestampStartConversation;
    }
  }

  @override
  void clear() => _lastStart.clear();
}
