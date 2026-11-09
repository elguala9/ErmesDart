part of 'nat_cipher_session.dart';

/// Per-peer cipher lookup and shared-secret derivation of
/// [NatCipherSession].
extension _NatCipherSessionHandler on NatCipherSession {
  /// Returns the peer's [ErmesPeerCipher] from the global handler, creating
  /// and registering one on first access.
  ErmesPeerCipher get _cipher {
    final handler = ErmesPeerCipherHandler();
    final key = peerCipherKey(peerId, context);
    final existing = handler.get(key);
    if (existing != null) {
      return existing;
    }
    final created = createErmesPeerCipher() as ErmesPeerCipher;
    handler.set(key, created);
    return created;
  }

  /// Derives the AES shared-secret cipher from our key pair and the peer's
  /// public key via ECDH.
  ISymmetricCipher _deriveShared(String peerPublicKey) =>
      deriveSharedSecretCipher(
        _kx,
        peerPublicKey,
        context,
        SymmetricAlgorithm.aes,
      );
}

/// Generates a random 256-bit AES key as a lowercase hex string.
String _randomAesKeyHex() {
  // Same 256-bit AES key generation the core's ErmesPeerKeyRotator uses.
  final random = Random.secure();
  final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
  return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Returns true when [needle] appears as a contiguous subsequence of
/// [haystack].
bool _contains(Uint8List haystack, Uint8List needle) {
  if (needle.isEmpty || needle.length > haystack.length) {
    return false;
  }
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) {
      return true;
    }
  }
  return false;
}
