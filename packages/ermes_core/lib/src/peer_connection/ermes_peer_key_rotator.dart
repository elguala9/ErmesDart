import 'dart:async';
import 'dart:math';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../service/ermes_service.dart';

/// Rotates the symmetric encryption key for a peer, triggered either by a
/// periodic timer or after a configured number of sent messages.
class ErmesPeerKeyRotator {
  /// Creates a rotator with the target service, remote id and the message-count
  /// and time-based rotation intervals.
  ErmesPeerKeyRotator({
    required IErmesService service,
    required IdAccountType remotePeerId,
    required int intervalMessages,
    required int intervalSeconds,
  })  : _service = service,
        _remotePeerId = remotePeerId,
        _intervalMessages = intervalMessages,
        _intervalSeconds = intervalSeconds;

  /// Service used to send newly generated keys to the peer.
  final IErmesService _service;
  /// Identifier of the peer whose key is rotated.
  final IdAccountType _remotePeerId;
  /// Number of sent messages that triggers a rotation.
  final int _intervalMessages;
  /// Time interval, in seconds, between periodic rotations.
  final int _intervalSeconds;

  /// Periodic rotation timer, active while the rotator is running.
  Timer? _timer;
  /// Messages sent since the last rotation.
  int _messageCount = 0;
  /// Whether the rotator has been disposed.
  bool _disposed = false;

  /// Starts the periodic key-rotation timer.
  void start() {
    _timer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _rotate(),
    );
  }

  /// Increments the message counter and rotates the key once the message
  /// interval is reached.
  void onMessageSent() {
    _messageCount++;
    if (_messageCount >= _intervalMessages) {
      _rotate();
    }
  }

  /// Stops the timer and marks the rotator as disposed.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Generates a fresh AES key, registers it locally and sends it to the peer.
  void _rotate() {
    if (_disposed) {
      return;
    }

    _messageCount = 0;

    final IErmesPeerCipher? peerCipher =
        ErmesPeerCipherHandler().get(_remotePeerId);
    if (peerCipher == null) {
      return;
    }

    final newKeyHex = _generateAesKeyHex();
    final newCipher = generateSymmetric(newKeyHex, SymmetricAlgorithm.aes);

    peerCipher.addEncryptCipher(newCipher);

    final service = _service;
    if (service is ErmesService) {
      service.sendNewKey(
        algorithm: SymmetricAlgorithm.aes,
        key: newKeyHex,
      );
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
