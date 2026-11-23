import '../../exceptions/ermes_exception.dart';

/// Which payload variant an outer envelope carries (RFC section 7.1).
enum EnvelopePayloadKind {
  /// Plaintext nested JSON in `message`.
  plaintext,

  /// Encrypted `messageSerialized` with its key `digest`.
  encrypted,
}

/// Applies the RFC section 7.1 presence rule to a decoded envelope.
///
/// Exactly one of `message` or `messageSerialized` must be present, and
/// `digest` is present iff `messageSerialized` is present. The rule is the
/// same for every major, the legacy unversioned form included. Throws
/// [ErmesSerializationException] on any violation or wrongly typed field.
EnvelopePayloadKind checkEnvelopePresence(Map<String, dynamic> json) {
  final hasMessage = json.containsKey('message');
  final hasSerialized = json.containsKey('messageSerialized');
  final hasDigest = json.containsKey('digest');
  if (json['integrityCheckValue'] == null) {
    throw ErmesSerializationException('Envelope lacks integrityCheckValue');
  }
  if (hasMessage == hasSerialized) {
    throw ErmesSerializationException(
      'Envelope must carry exactly one of message / messageSerialized',
    );
  }
  if (hasDigest != hasSerialized) {
    throw ErmesSerializationException(
      'digest must be present iff messageSerialized is present',
    );
  }
  if (hasMessage) {
    if (json['message'] is! Map<String, dynamic>) {
      throw ErmesSerializationException('message must be a JSON object');
    }
    return EnvelopePayloadKind.plaintext;
  }
  if (json['messageSerialized'] is! String || json['digest'] is! String) {
    throw ErmesSerializationException(
      'messageSerialized and digest must be strings',
    );
  }
  return EnvelopePayloadKind.encrypted;
}
