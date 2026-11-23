import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../../exceptions/ermes_exception.dart';
import '../converters/converters.dart';
import 'message_enums.dart';
import 'message_root_presence.dart';
import 'protocol_version.dart';

export 'message_root_presence.dart';
export 'message_root_storage.dart';

/// Root message structure containing serialized data and integrity check
class MessageRoot implements IErmesSerializable {
  /// Creates a root message with its payload and integrity metadata.
  const MessageRoot({
    required this.messageSerialized,
    required this.integrityCheckValue,
    this.digest,
    this.messageJson,
  });

  /// Builds a [MessageRoot] from JSON (RFC ermes-protocol, section 7.1).
  ///
  /// `v` absent is the legacy "1.0" form; otherwise `v` must be a "X.Y"
  /// string whose major is supported. Every major, legacy included, obeys
  /// the presence rule of [checkEnvelopePresence]: plaintext `message`, or
  /// `messageSerialized` with its `digest`, never both. Throws
  /// [ErmesSerializationException] on a bad version or presence violation.
  factory MessageRoot.fromJson(Map<String, dynamic> json) {
    ProtocolVersion.parse(json['v']).requireSupported();
    final kind = checkEnvelopePresence(json);
    final Object? rawIntegrity = json['integrityCheckValue'];
    final integrity = rawIntegrity ?? '';
    final message = json['message'];
    if (kind == EnvelopePayloadKind.plaintext &&
        message is Map<String, dynamic>) {
      return MessageRoot(
        messageJson: message,
        messageSerialized: Uint8List(0),
        integrityCheckValue: integrity,
      );
    }
    return MessageRoot(
      messageSerialized: const Uint8ListConverter()
          .fromJson(json['messageSerialized'].toString()),
      integrityCheckValue: integrity,
      digest: Digest(hex.decode(json['digest'].toString())),
    );
  }

  /// Wire value of the envelope field `v`.
  static final String _version = ProtocolVersion.current.toString();

  /// Serialized message data (for encrypted or v1 plaintext)
  final Uint8List messageSerialized;

  /// Message as nested JSON (for v2 plaintext)
  final Map<String, dynamic>? messageJson;

  /// Integrity check value (should be String)
  final Object integrityCheckValue;

  /// Digest of the message (key) - only present for encrypted messages
  final Digest? digest;

  /// Returns a copy of this root message with the given fields replaced.
  MessageRoot copyWith({
    Uint8List? messageSerialized,
    Map<String, dynamic>? messageJson,
    Object? integrityCheckValue,
    Digest? digest,
  }) =>
      MessageRoot(
        messageSerialized: messageSerialized ?? this.messageSerialized,
        messageJson: messageJson ?? this.messageJson,
        integrityCheckValue: integrityCheckValue ?? this.integrityCheckValue,
        digest: digest ?? this.digest,
      );

  /// Serializes this root message to JSON using the current protocol version.
  @override
  Map<String, dynamic> toJson() {
    final integrityCheckString = integrityCheckValue.toString();

    // Plaintext message with nested JSON
    if (messageJson != null && digest == null) {
      return {
        'v': _version,
        'message': messageJson,
        'integrityCheckValue': integrityCheckString,
      };
    }

    // Encrypted message: messageSerialized is never emitted without digest.
    final keyDigest = digest;
    if (keyDigest == null) {
      throw ErmesSerializationException(
        'Cannot serialize messageSerialized without digest (RFC 7.1)',
      );
    }
    return {
      'v': _version,
      'messageSerialized': const Uint8ListConverter().toJson(messageSerialized),
      'integrityCheckValue': integrityCheckString,
      'digest': hex.encode(keyDigest.bytes),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRoot &&
          runtimeType == other.runtimeType &&
          messageSerialized == other.messageSerialized &&
          messageJson == other.messageJson &&
          integrityCheckValue == other.integrityCheckValue &&
          digest == other.digest;

  @override
  int get hashCode =>
      Object.hash(messageSerialized, messageJson, integrityCheckValue, digest);

  @override
  String toString() =>
      'MessageRoot(messageSerialized: $messageSerialized, '
      'messageJson: $messageJson, integrityCheckValue: $integrityCheckValue, '
      'digest: $digest)';
}
