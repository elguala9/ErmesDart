import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../common/storage_types.dart';
import '../common/type_aliases.dart';
import 'message_root.dart';

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
