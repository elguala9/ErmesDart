import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../converters/converters.dart';
import 'message_enums.dart';
import 'protocol_version.dart';

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
  /// string whose major is supported. Both majors use the same presence
  /// rule: `message` is plaintext nested JSON, else `messageSerialized`
  /// with an optional `digest`. Throws [ErmesSerializationException] on an
  /// unsupported or malformed version.
  factory MessageRoot.fromJson(Map<String, dynamic> json) {
    ProtocolVersion.parse(json['v']).requireSupported();
    final integrity = json['integrityCheckValue'] as Object;
    if (json.containsKey('message')) {
      return MessageRoot(
        messageJson: json['message'] as Map<String, dynamic>,
        messageSerialized: Uint8List(0),
        integrityCheckValue: integrity,
      );
    }
    final digest = json['digest'];
    return MessageRoot(
      messageSerialized: const Uint8ListConverter()
          .fromJson(json['messageSerialized'] as String),
      integrityCheckValue: integrity,
      digest: digest is String ? Digest(hex.decode(digest)) : null,
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

    // Serialized (encrypted or legacy plaintext) message
    return {
      'v': _version,
      'messageSerialized': const Uint8ListConverter().toJson(messageSerialized),
      'integrityCheckValue': integrityCheckString,
      if (digest != null) 'digest': hex.encode(digest!.bytes),
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
