import 'package:iermes/iermes.dart';

/// Validation rules for the identifiers accepted at Ermes' public entry points.
///
/// A peer is identified by its public key: a 32-byte value rendered as a
/// 64-character hexadecimal string. Centralising the rule here keeps every
/// entry point (connection opening, sending, book lookups) consistent and
/// makes the accepted format easy to evolve.
class ErmesIdValidator {
  ErmesIdValidator._();

  /// Number of hex characters in a peer public key (32 bytes => 64 hex chars).
  static const int publicKeyHexLength = 64;

  static final RegExp _publicKeyPattern =
      RegExp('^[0-9a-fA-F]{$publicKeyHexLength}\$');

  /// Whether [id] is a syntactically valid peer public key.
  static bool isValidPublicKey(String id) => _publicKeyPattern.hasMatch(id);

  /// Throws [ErmesValidationException] unless [id] is a valid peer public key.
  ///
  /// [field] names the offending parameter in the error message (e.g. `peer`).
  static void validatePublicKey(String id, {String field = 'peer'}) {
    if (!isValidPublicKey(id)) {
      throw ErmesValidationException(
        'Invalid $field public key format: expected $publicKeyHexLength '
        'hex characters, got "${_describe(id)}"',
      );
    }
  }

  /// Renders [id] for error messages without leaking unbounded input.
  static String _describe(String id) =>
      id.length <= 80 ? id : '${id.substring(0, 77)}...';
}
