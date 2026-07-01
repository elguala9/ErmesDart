// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart'
    show ISymmetricCipher, SymmetricAlgorithm;
import 'package:ermes_cipher/ermes_cipher.dart';

/// Owns the real Ermes crypto for one peer link in the encryption scenarios.
///
/// Wraps an ephemeral P-256 ECDH key pair and the per-peer
/// [ErmesPeerCipher] registered in the global [ErmesPeerCipherHandler] that
/// `OrcErmes`'s send/receive path reads. The derivation mirrors
/// `ECDHKeyExchangeService.generateISymmetric` but takes only the peer's
/// public key (never its private key) off the wire.
class NatCipherSession {
  NatCipherSession(this.peerId, {required this.tag});

  final String peerId;
  final String tag;

  late final ECDHKeyExchangeService _kx;
  ISymmetricCipher? _shared;
  ISymmetricCipher? _pendingEncrypt;

  bool _decryptReady = false;
  bool _encryptReady = false;

  /// The peer can decrypt what we send only after we register the encrypt
  /// cipher; until then our `OrcErmes.send` calls go out as plaintext.
  bool get encryptReady => _encryptReady;

  /// We have registered the decrypt cipher and can read encrypted frames.
  bool get decryptReady => _decryptReady;

  /// Generates the ephemeral ECDH key pair. Call once before the handshake.
  Future<void> init() async {
    _kx = await ECDHKeyExchangeService.generateNew() as ECDHKeyExchangeService;
  }

  /// Our ECDH public key to publish to the peer (handshake frame payload).
  String get publicKey => _kx.publicKey;

  /// Derives the shared AES cipher from the peer's ECDH public key and
  /// registers it for DECRYPTION only. Idempotent.
  void registerDecrypt(String peerPublicKey) {
    if (_decryptReady) {
      return;
    }
    _shared = _deriveShared(peerPublicKey);
    _cipher.addDecryptCipher(_shared!);
    _decryptReady = true;
    print('[$tag] Cipher: shared secret derived; decrypt cipher registered.');
  }

  /// Registers the already-derived shared cipher for ENCRYPTION, so every
  /// subsequent send is ciphertext on the wire. Call only once the peer has
  /// confirmed it can decrypt.
  void enableEncrypt() {
    if (_encryptReady || _shared == null) {
      return;
    }
    _cipher.addEncryptCipher(_shared!);
    _encryptReady = true;
    print('[$tag] Cipher: encrypt cipher registered; sends now ciphertext.');
  }

  /// Phase 1 of a rekey: generates a fresh AES key and returns its hex WITHOUT
  /// switching the encrypt cipher yet, so the announcement of the new key still
  /// goes out under the old (peer-readable) key. Pair with
  /// [commitRotatedEncryptKey] once the peer has registered the new key.
  String rotateEncryptKeyDeferred() {
    final newKeyHex = _randomAesKeyHex();
    _pendingEncrypt = generateSymmetric(newKeyHex, SymmetricAlgorithm.aes);
    return newKeyHex;
  }

  /// Phase 2 of a rekey: switches the encrypt cipher to the key returned by
  /// [rotateEncryptKeyDeferred], dropping the old one so later sends use the
  /// new key. The old decrypt cipher stays registered for in-flight frames.
  void commitRotatedEncryptKey() {
    final pending = _pendingEncrypt;
    if (pending == null) {
      return;
    }
    final old = _shared;
    _cipher.addEncryptCipher(pending);
    if (old != null) {
      _cipher.removeEncryptCipher(old.keyId);
    }
    _shared = pending;
    _pendingEncrypt = null;
    print('[$tag] Cipher: rotated encrypt key.');
  }

  /// Registers a peer-rotated key (from a `newKey` frame) as a decrypt cipher
  /// via the same factory the core's `_handleNewKey` uses.
  void registerRotatedDecrypt(String keyHex) {
    final cipher = generateSymmetric(keyHex, SymmetricAlgorithm.aes);
    _cipher.addDecryptCipher(cipher);
    print('[$tag] Cipher: registered rotated decrypt key.');
  }

  /// Locally proves the registered cipher turns [plaintext] into ciphertext
  /// that no longer contains the plaintext bytes — the exact transform the
  /// send path applies, so it stands in for an on-wire byte tap.
  bool producesCiphertextFor(Uint8List plaintext) {
    final cipher = _shared;
    if (cipher == null) {
      return false;
    }
    final encrypted = _cipher.encrypt(plaintext).encryptedData;
    return !_contains(encrypted, plaintext);
  }

  ErmesPeerCipher get _cipher {
    final handler = ErmesPeerCipherHandler();
    final existing = handler.get(peerId);
    if (existing != null) {
      return existing;
    }
    final created = createErmesPeerCipher() as ErmesPeerCipher;
    handler.set(peerId, created);
    return created;
  }

  ISymmetricCipher _deriveShared(String peerPublicKey) =>
      deriveSharedSecretCipher(_kx, peerPublicKey, SymmetricAlgorithm.aes);

  String _randomAesKeyHex() {
    // Same 256-bit AES key generation the core's ErmesPeerKeyRotator uses.
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _contains(Uint8List haystack, Uint8List needle) {
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
}
