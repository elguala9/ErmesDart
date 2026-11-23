import 'dart:async';
import 'dart:math';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../service/ermes_service.dart';

/// Rotates the symmetric session key for a peer after N sent messages, N
/// being fixed by the protocol version (RFC 7.5). There is no time-based
/// symmetric rotation.
class ErmesPeerKeyRotator {
  /// Creates a rotator for [service]. [intervalMessages] is a test seam only
  /// (N is a protocol constant); it defaults to the current version's N.
  ErmesPeerKeyRotator({
    required IErmesService service,
    int? intervalMessages,
  })  : _service = service,
        _intervalMessages = intervalMessages ??
            ErmesProtocolParameters.current.sessionKeyRotationMessages;

  /// Service used to send newly generated keys to the peer.
  final IErmesService _service;
  /// Number of sent messages that triggers a rotation.
  final int _intervalMessages;
  /// Messages sent since the last rotation.
  int _messageCount = 0;
  /// Whether the rotator has been disposed.
  bool _disposed = false;

  /// Whether a rotation is in flight (newkey not yet dispatched).
  bool _rotating = false;

  /// Increments the message counter and rotates the key once the message
  /// interval is reached.
  void onMessageSent() {
    _messageCount++;
    if (_messageCount >= _intervalMessages) {
      unawaited(rotate());
    }
  }

  /// Marks the rotator as disposed; later rotations are ignored.
  void dispose() => _disposed = true;

  /// Generates a fresh AES key and delivers it to the peer (RFC §7.4).
  ///
  /// The `newkey` frame is encrypted under the current outbound key and
  /// awaited; only afterwards the new key becomes current and the previous
  /// outbound key is dropped. Overlapping calls are ignored.
  Future<void> rotate() async {
    if (_disposed || _rotating) {
      return;
    }
    _messageCount = 0;
    final service = _service;
    if (service is! ErmesService) {
      return;
    }
    final peerCipher = ErmesPeerCipherHandler().get(service.cipherKey);
    if (peerCipher == null) {
      return;
    }
    _rotating = true;
    try {
      final previous =
          peerCipher.hasEncryptCipher ? peerCipher.currentEncryptKeyId : null;
      final newKeyHex = _generateAesKeyHex();
      await service.sendNewKey(
        algorithm: SymmetricAlgorithm.aes,
        key: newKeyHex,
      );
      final newCipher = generateSymmetric(newKeyHex, SymmetricAlgorithm.aes);
      peerCipher.addEncryptCipher(newCipher);
      if (previous != null && previous != newCipher.keyId) {
        peerCipher.removeEncryptCipher(previous);
      }
    } finally {
      _rotating = false;
    }
  }

  /// Generates a random 256-bit AES key encoded as a hex string.
  String _generateAesKeyHex() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return keyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
