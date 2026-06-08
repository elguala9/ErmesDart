import 'dart:async';
import 'dart:math';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import 'ermes_service.dart';

class ErmesPeerKeyRotator {
  ErmesPeerKeyRotator({
    required IErmesService service,
    required IdAccountType remotePeerId,
    required int intervalMessages,
    required int intervalSeconds,
  })  : _service = service,
        _remotePeerId = remotePeerId,
        _intervalMessages = intervalMessages,
        _intervalSeconds = intervalSeconds;

  final IErmesService _service;
  final IdAccountType _remotePeerId;
  final int _intervalMessages;
  final int _intervalSeconds;

  Timer? _timer;
  int _messageCount = 0;
  bool _disposed = false;

  void start() {
    _timer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _rotate(),
    );
  }

  void onMessageSent() {
    _messageCount++;
    if (_messageCount >= _intervalMessages) {
      _rotate();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

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

  String _generateAesKeyHex() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return keyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
