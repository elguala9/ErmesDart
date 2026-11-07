import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';

import 'exceptions.dart';

/// A decrypt key with its optional message-id bounds (RFC section 7.4).
/// A null bound is open-ended on that side.
typedef DecryptKeyEntry = ({
  ICipher cipher,
  int? startMessage,
  int? endMessage,
});

/// Bounded store of decryption ciphers for a single peer, keyed by digest hex.
///
/// Keys are never retired by wall clock: per RFC section 7.4 `start` and
/// `expiration` are advisory on the receiver. Retention is bounded by count
/// instead: at most [capacity] keys are kept, in insertion order, and the
/// oldest is evicted first. Re-adding an existing digest refreshes it.
/// Each key carries the `startMessage`/`endMessage` id range it covers.
class DecryptKeyRing {
  /// Creates a ring that keeps at most [capacity] keys.
  DecryptKeyRing({this.capacity = defaultCapacity}) {
    if (capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'must be at least 1');
    }
  }

  /// Default number of decrypt keys retained per peer.
  static const int defaultCapacity = 4;

  /// Maximum number of keys retained.
  final int capacity;

  final Map<String, DecryptKeyEntry> _entries = {};

  /// Cipher registered under [keyHex], or null when absent.
  ICipher? operator [](String keyHex) => _entries[keyHex]?.cipher;

  /// Digest hex strings currently retained, oldest first.
  List<String> get keys => _entries.keys.toList();

  /// Adds (or refreshes) [cipher] under [keyHex] with its message-id bounds,
  /// then applies the retention bound.
  void add(
    String keyHex,
    ICipher cipher, {
    int? startMessage,
    int? endMessage,
  }) {
    _entries
      ..remove(keyHex)
      ..[keyHex] =
          (cipher: cipher, startMessage: startMessage, endMessage: endMessage);
    trim();
  }

  /// Removes the cipher registered under [keyHex], if present.
  void remove(String keyHex) => _entries.remove(keyHex);

  /// Evicts the oldest keys until at most [capacity] remain.
  void trim() {
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Decrypts [data] with the key [keyHex].
  /// Throws [CipherException] when the key is unknown or decryption fails.
  Uint8List decrypt(String keyHex, Uint8List data) {
    final cipher = this[keyHex];
    if (cipher == null) {
      throw CipherException(
        'Decryption cipher not found for key $keyHex (available: $keys)',
      );
    }
    try {
      return Uint8List.fromList(cipher.decrypt(data));
    } catch (e) {
      throw CipherException('Decryption failed for key $keyHex: $e');
    }
  }

  /// Whether [messageId] lies within the bounds of key [keyHex].
  /// Throws [CipherException] when the key is unknown.
  bool isIdInBounds(String keyHex, int messageId) {
    final entry = _entries[keyHex];
    if (entry == null) {
      throw CipherException('Unknown decrypt key $keyHex');
    }
    final start = entry.startMessage;
    final end = entry.endMessage;
    return (start == null || messageId >= start) &&
        (end == null || messageId <= end);
  }
}
