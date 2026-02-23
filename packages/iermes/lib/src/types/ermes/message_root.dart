import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../converters/converters.dart';
import 'message_enums.dart';

/// Root message structure containing serialized data and integrity check
@includeInBarrelFile
class MessageRoot implements IErmesSerializable {
  const MessageRoot({
    required this.messageSerialized,
    required this.integrityCheckValue,
    this.digest,
    this.messageJson,
  });

  // MANUAL SERIALIZATION: Protocol versioning (v1/v2 branching)
  factory MessageRoot.fromJson(Map<String, dynamic> json) {
    final version = json['v'] as int? ?? 1;

    if (version == 2) {
      // Protocol v2: plaintext has nested JSON, encrypted has base64
      if (json.containsKey('message')) {
        // Plaintext message with nested JSON
        return MessageRoot(
          messageJson: json['message'] as Map<String, dynamic>,
          messageSerialized: Uint8List(0), // Empty for plaintext
          integrityCheckValue: json['integrityCheckValue'] as Object,
        );
      } else {
        // Encrypted message with base64 serialized data
        return MessageRoot(
          messageSerialized: const Uint8ListConverter()
              .fromJson(json['messageSerialized'] as String),
          integrityCheckValue: json['integrityCheckValue'] as Object,
          digest: json['digest'] != null
              ? Digest(hex.decode(json['digest'] as String))
              : null,
        );
      }
    } else {
      // Legacy v1: backward compatibility
      return MessageRoot(
        messageSerialized: const Uint8ListConverter()
            .fromJson(json['messageSerialized'] as String),
        integrityCheckValue: json['integrityCheckValue'] as Object,
        digest: json['digest'] != null
            ? Digest(hex.decode(json['digest'] as String))
            : null,
      );
    }
  }

  /// Protocol version number
  static const int _version = 2;

  /// Serialized message data (for encrypted or v1 plaintext)
  final Uint8List messageSerialized;

  /// Message as nested JSON (for v2 plaintext)
  final Map<String, dynamic>? messageJson;

  /// Integrity check value (should be String)
  final Object integrityCheckValue;

  /// Digest of the message (key) - only present for encrypted messages
  final Digest? digest;

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

  // MANUAL SERIALIZATION: Protocol versioning (v1/v2 branching)
  @override
  Map<String, dynamic> toJson() {
    // Plaintext message with nested JSON (v2)
    if (messageJson != null && digest == null) {
      return {
        'v': _version,
        'message': messageJson,
        'integrityCheckValue': integrityCheckValue,
      };
    }

    // Encrypted message (v2 or v1 compatible)
    return {
      'v': _version,
      'messageSerialized': const Uint8ListConverter().toJson(messageSerialized),
      'integrityCheckValue': integrityCheckValue,
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
