import 'dart:typed_data';


import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../common/storage_types.dart';
import '../common/type_aliases.dart';
import '../converters/converters.dart';
import 'message_enums.dart';

/// Root message structure containing serialized data and integrity check
class MessageRoot implements IErmesSerializable {
  /// Creates a root message with its payload and integrity metadata.
  const MessageRoot({
    required this.messageSerialized,
    required this.integrityCheckValue,
    this.digest,
    this.messageJson,
  });

  /// Builds a [MessageRoot] from JSON, handling protocol v1/v2 branching.
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
  // MANUAL SERIALIZATION: Protocol versioning (v1/v2 branching)
  @override
  Map<String, dynamic> toJson() {
    final integrityCheckString = integrityCheckValue.toString();

    // Plaintext message with nested JSON (v2)
    if (messageJson != null && digest == null) {
      return {
        'v': _version,
        'message': messageJson,
        'integrityCheckValue': integrityCheckString,
      };
    }

    // Encrypted message (v2 or v1 compatible)
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

/// MessageRoot with storage compliance - implements StorageType for persistence
class MessageRootStorage extends MessageRoot implements StorageType {
  /// Creates a storable root message carrying its persistence id.
  const MessageRootStorage({
    required this.id,
    required super.messageSerialized,
    required super.integrityCheckValue,
    super.digest,
    super.messageJson,
  });

  /// Builds a [MessageRootStorage] from its JSON representation.
  factory MessageRootStorage.fromJson(Map<String, dynamic> json) {
    final baseMessageRoot = MessageRoot.fromJson(json);
    return MessageRootStorage(
      id: json['id'] as IdType,
      messageSerialized: baseMessageRoot.messageSerialized,
      messageJson: baseMessageRoot.messageJson,
      integrityCheckValue: baseMessageRoot.integrityCheckValue,
      digest: baseMessageRoot.digest,
    );
  }

  /// Create MessageRootStorage from a MessageRoot instance and an id
  factory MessageRootStorage.fromMessageRoot(
    MessageRoot messageRoot,
    IdType id,
  ) =>
      MessageRootStorage(
        id: id,
        messageSerialized: messageRoot.messageSerialized,
        messageJson: messageRoot.messageJson,
        integrityCheckValue: messageRoot.integrityCheckValue,
        digest: messageRoot.digest,
      );

  /// Persistence identifier of this stored message.
  @override
  final IdType id;

  /// Serializes this stored message to JSON, including its id.
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'id': id,
    };
  }
  /// Returns a copy of this stored message with the given fields replaced.
  @override
  MessageRootStorage copyWith({
    IdType? id,
    Uint8List? messageSerialized,
    Map<String, dynamic>? messageJson,
    Object? integrityCheckValue,
    Digest? digest,
  }) =>
      MessageRootStorage(
        id: id ?? this.id,
        messageSerialized: messageSerialized ?? this.messageSerialized,
        messageJson: messageJson ?? this.messageJson,
        integrityCheckValue: integrityCheckValue ?? this.integrityCheckValue,
        digest: digest ?? this.digest,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRootStorage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messageSerialized == other.messageSerialized &&
          messageJson == other.messageJson &&
          integrityCheckValue == other.integrityCheckValue &&
          digest == other.digest;

  @override
  int get hashCode =>
      Object.hash(id, messageSerialized, messageJson, integrityCheckValue,
          digest);

  @override
  String toString() =>
      'MessageRootStorage(id: $id, messageSerialized: $messageSerialized, '
      'messageJson: $messageJson, integrityCheckValue: $integrityCheckValue, '
      'digest: $digest)';
      
  /// JSON view of this stored message, equivalent to [toJson].
  @override
  Map<String, dynamic> get json => toJson();

  /// Convert MessageRootStorage back to MessageRoot (discarding the id)
  MessageRoot toMessageRoot() =>
      MessageRoot(
        messageSerialized: messageSerialized,
        messageJson: messageJson,
        integrityCheckValue: integrityCheckValue,
        digest: digest,
      );
}
