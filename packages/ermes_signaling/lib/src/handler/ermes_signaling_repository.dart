import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// 4️⃣ ErmesSignalingRepository - Repository signaling
/// Tradotto da: ErmesSignalingRepository.ts
///
/// Responsabilità:
/// - Coordinamento server/handler
/// - Gestione callback segnali
/// - Registrazione listener
@dependencyInjectable
class ErmesSignalingRepository
    implements IErmesSignalingRepository<ISignalErmes> {
  /// Creates a repository wiring the server and handler and subscribing to
  /// incoming signals.
  ErmesSignalingRepository(this.signalingServer, this.signalHandler) {
    signalingServer.onSignal(_onSignalPrivate);
  }

  factory ErmesSignalingRepository.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final signalingServer = RegistryManager.instance
        .getInstance<IErmesSignalingServer>(
          key: key,
        ); // GENERATED CODE - DO NOT MODIFY BY HAND
    final signalHandler = RegistryManager.instance
        .getInstance<IErmesSignalingHandler<IShspPeer>>(
          key: key,
        ); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesSignalingRepository(
      // GENERATED CODE - DO NOT MODIFY BY HAND
      signalingServer, // GENERATED CODE - DO NOT MODIFY BY HAND
      signalHandler, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Server used to send and receive signals over the signaling channel.
  final IErmesSignalingServer signalingServer;

  /// Handler responsible for creating and processing signals.
  final IErmesSignalingHandler<IShspPeer> signalHandler;

  /// Optional callback invoked when a signal is received.
  OnSignalCallback<ISignalErmes>? onAnswerCallback;

  /// The most recently received signal, if any.
  ISignalErmes? _lastSignal;

  /// Reports whether the underlying signaling server is connected.
  @override
  Future<bool> isConnected() => signalingServer.isConnected();

  /// Tears down the signaling server.
  @override
  Future<void> destroy() => signalingServer.destroy();

  /// Returns the local account identifier from the signaling server.
  @override
  Future<String> getIdAccount() => signalingServer.getIdAccount();

  /// Creates a fresh local signal and sends it to the given recipient.
  @override
  Future<void> sendSignal(String to) async {
    final signal = await signalHandler.createSignal();
    await signalingServer.setSignal(signal, to);
  }

  /// Fetches the signal published by the given sender.
  @override
  Future<ISignalErmes> getSignal(String from) =>
      signalingServer.getSignal(from);

  /// Builds and returns the local peer's own signal.
  @override
  Future<ISignalErmes> getSignalOwner() async {
    final signal = signalHandler.createSignal();
    return signal;
  }

  /// Returns the last received signal without contacting the server.
  @override
  Future<ISignalErmes?> getLastSignal() async => _lastSignal;

  /// Re-fetches the last signal from the server, falling back to the cached
  /// value on error.
  @override
  Future<ISignalErmes?> getLastSignalForced() async {
    if (_lastSignal == null) {
      return null;
    }
    try {
      final signal = await signalingServer.getSignal(
        _lastSignal!.publicKey,
        forceRefresh: true,
      );
      _lastSignal = signal;
      return signal;
    } on Object catch (_) {
      return _lastSignal;
    }
  }

  /// Caches the incoming signal and forwards it to the registered callback.
  void _onSignalPrivate(ISignalErmes input) {
    _lastSignal = input;
    if (onAnswerCallback == null) {
      return;
    }
    onAnswerCallback!(input);
  }

  /// Registers the callback invoked whenever a signal arrives.
  @override
  void onSignal(OnSignalCallback<ISignalErmes> callback) {
    onAnswerCallback = callback;
  }

  /// Compares two signals for equality by their string representation.
  @override
  bool compareSignalMessage(Object signal1, Object signal2) =>
      signal1.toString() == signal2.toString();

  /// Removes all listeners on the server and clears the signal callback.
  @override
  void removeAllListeners() {
    signalingServer.removeAllListeners();
    onAnswerCallback = null;
  }
}
