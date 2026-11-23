import 'dart:async';

import 'package:iermes/iermes.dart';

/// Inputs of [ErmesPubKeyRotator] (see [ErmesPubKeyRotatorFactory]).
class ErmesPubKeyRotatorInput {
  /// Creates the input. [interval] is a test seam only: T is a protocol
  /// constant (RFC 7.5) and defaults to the current version's value.
  const ErmesPubKeyRotatorInput({
    required this.renewKeyPair,
    required this.services,
    required this.rederive,
    required this.republish,
    this.interval,
  });

  /// Generates a fresh local ECDH key pair, returning its public half.
  final Future<String> Function() renewKeyPair;

  /// Services of every live Connection, told about the new public key.
  final Iterable<IErmesService> Function() services;

  /// Re-derives every Connection's session keys from the new key pair.
  final void Function() rederive;

  /// Re-publishes our signal (same IdSignaling, new public key).
  final Future<void> Function() republish;

  /// Rotation period; `null` uses the protocol's T.
  final Duration? interval;
}

/// Rotates the local encryption key pair every T (RFC 8.6): a new ECDH pair
/// is generated, announced in-band (`newpubkey` on every Connection) and
/// out-of-band (re-published signal), then the session keys are re-derived.
class ErmesPubKeyRotator {
  /// Creates a stopped rotator; prefer [ErmesPubKeyRotatorFactory].
  ErmesPubKeyRotator(this._input)
      : interval = _input.interval ??
            ErmesProtocolParameters.current.publicKeyRotationInterval;

  final ErmesPubKeyRotatorInput _input;

  /// Effective rotation period.
  final Duration interval;

  Timer? _timer;
  bool _rotating = false;
  bool _disposed = false;

  /// Whether the periodic timer is running.
  bool get isRunning => _timer?.isActive ?? false;

  /// Starts the periodic rotation; idempotent, ignored once disposed.
  void start() {
    if (_disposed || isRunning) {
      return;
    }
    _timer = Timer.periodic(interval, (_) => unawaited(rotate()));
  }

  /// Stops the timer for good; later rotations are ignored.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }

  /// Performs one rotation. The in-band `newpubkey` frames are dispatched
  /// BEFORE re-deriving, so they still travel under the outbound key the
  /// peer knows. Overlapping calls are ignored. Announcements are
  /// best-effort: a closed Connection must not stop the rotation.
  Future<void> rotate() async {
    if (_disposed || _rotating) {
      return;
    }
    _rotating = true;
    try {
      final key = await _input.renewKeyPair();
      for (final service in List.of(_input.services())) {
        await _bestEffort(() => service.sendNewPubKey(key: key));
      }
      _input.rederive();
      await _bestEffort(_input.republish);
    } finally {
      _rotating = false;
    }
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // The other channel (in-band / out-of-band) still carries the key.
    }
  }
}

/// Factory for [ErmesPubKeyRotator].
class ErmesPubKeyRotatorFactory {
  ErmesPubKeyRotatorFactory._();

  /// Creates a stopped rotator from [input].
  static ErmesPubKeyRotator create(ErmesPubKeyRotatorInput input) =>
      ErmesPubKeyRotator(input);
}
