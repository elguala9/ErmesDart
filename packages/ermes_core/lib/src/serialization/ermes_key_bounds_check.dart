import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../support/ermes_receive_stats.dart';
import 'ermes_message_decoder.dart';

/// Whether the inner id of [inner] lies within the startMessage/endMessage
/// bounds of the key that decrypted [decoded] (RFC section 7.4).
///
/// Plaintext frames and unbounded keys always pass. A violation is an
/// integrity failure (RFC section 7.1): it is counted once, as
/// `dropKeyBounds`, and the caller must drop the frame.
bool isWithinKeyBounds(
  DecodedEnvelope decoded,
  String cipherKey,
  InternalMessage inner,
) {
  final digest = decoded.digest;
  if (digest == null) {
    return true;
  }
  final peerCipher = ErmesPeerCipherHandler().get(cipherKey);
  try {
    if (peerCipher != null &&
        peerCipher.isIdInKeyBounds(digest, inner.message.getId())) {
      return true;
    }
  } on CipherException {
    // Key evicted between decrypt and check: treat as out of bounds.
  }
  ErmesReceiveStats.active?.onDropKeyBounds();
  return false;
}
