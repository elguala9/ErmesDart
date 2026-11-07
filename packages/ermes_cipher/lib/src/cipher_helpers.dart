import 'package:cryptdart/cryptdart.dart';
import 'package:crypto/crypto.dart';

/// Whether [cipher] has passed its expiration date. Used only for the
/// sender's own outbound-key bookkeeping (RFC section 7.4).
bool isCipherExpired(ICipher cipher) {
  final expiration = cipher.expirationDate;
  return expiration != null && expiration.isBefore(DateTime.now());
}

/// Hex form of a key digest, used as a stable map key.
String digestHex(Digest id) =>
    id.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
