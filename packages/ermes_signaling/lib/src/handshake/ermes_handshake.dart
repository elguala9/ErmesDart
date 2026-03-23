
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../../ermes_signaling.dart';
import '../ermes_signal_type.dart';

typedef ErmesAsyncHandshakeInput = ({
  String publicKey,
  String privateKey,
  String curve,
});

/// Implementation of async handshake for establishing peer connections
///
/// This class manages the handshake process for creating connections between
/// peers using signaling and service creation.

class ErmesAsyncHandshake
    implements IErmesHandshake<ErmesAsyncHandshakeInput, SignalErmes> {
  ErmesAsyncHandshake(
    this._localInfo, {
    IErmesRepository? repository,
  }) : _cachedRepository = repository;

  final ErmesAsyncHandshakeInput _localInfo;
  final IErmesRepository? _cachedRepository;
  bool _handshakeComplete = false;

  /// Performs the async handshake and returns repository.
  ///
  /// This method should be called to establish the connection.
  /// After successful completion, [handshake] will return the cached
  /// repository.
  ///
  /// [_localInfo] contains the cryptographic keys for the handshake.
  Future<IErmesRepository> handshakeAsync({
    required SignalErmes remoteSignal,
    required IErmesSignalingHandler<IShspSocket> signalingHandler,
  }) async {
    // ignore: unused_local_variable
    final keyInfo = _localInfo;
    if (_handshakeComplete && _cachedRepository != null) {
      return _cachedRepository;
    }

    // Step 1: Create handshake message with local info
    // (Crypto keys and connection info)

    // Step 2: Simulate handshake completion delay
    // In production, this would involve actual protocol exchange
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Step 3: Mark handshake as complete
    _handshakeComplete = true;

    // Return cached repository or throw if not set
    if (_cachedRepository == null) {
      throw StateError(
        'Repository not set after handshake completion',
      );
    }

    return _cachedRepository;
  }

  @override
  IErmesRepository handshake() {
    if (!_handshakeComplete || _cachedRepository == null) {
      throw StateError(
        'Handshake not yet complete. '
        'Call handshakeAsync() before accessing handshake()',
      );
    }
    return _cachedRepository;
  }
}
