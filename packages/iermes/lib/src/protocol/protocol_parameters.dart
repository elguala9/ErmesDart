import '../exceptions/ermes_exception.dart';
import '../types/ermes/protocol_version.dart';

/// Protocol parameters fixed by the negotiated minor version
/// (RFC ermes-protocol section 7.5). A peer MUST NOT deviate from them;
/// changing any value requires a new minor version.
class ErmesProtocolParameters {
  /// Creates a parameter set.
  const ErmesProtocolParameters({
    required this.sessionKeyRotationMessages,
    required this.publicKeyRotationInterval,
    required this.missingMessagesThreshold,
    required this.retentionWindow,
  });

  /// Returns the set fixed by [version]; throws [ErmesValidationException]
  /// for a version without a defined set.
  factory ErmesProtocolParameters.forVersion(ProtocolVersion version) {
    if (version.major == 3 && version.minor == 0) {
      return v3_0;
    }
    throw ErmesValidationException(
      'No protocol parameters defined for version $version',
    );
  }

  /// Version 3.0 set (RFC section 7.5 table).
  static const ErmesProtocolParameters v3_0 = ErmesProtocolParameters(
    sessionKeyRotationMessages: 1000,
    publicKeyRotationInterval: Duration(seconds: 86400),
    missingMessagesThreshold: 10,
    retentionWindow: Duration(seconds: 3600),
  );

  /// Set of [ProtocolVersion.current].
  static const ErmesProtocolParameters current = v3_0;

  /// N: symmetric session-key rotation every N sent messages (RFC 8.3).
  final int sessionKeyRotationMessages;

  /// T: encryption public-key rotation interval (RFC 8.6).
  final Duration publicKeyRotationInterval;

  /// Missing ids that trigger the reactive array request (RFC 9.4).
  final int missingMessagesThreshold;

  /// Retention window of the retransmission mapping (RFC 10.2).
  final Duration retentionWindow;
}
