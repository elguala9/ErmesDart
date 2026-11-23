import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../common/storage_types.dart';
import '../common/type_aliases.dart';
import '../converters/uint8list_converter.dart';
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
    this.storedAtMs,
    this.envelope,
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
      storedAtMs: json['storedAt'] as int?,
      envelope: _envelopeFromJson(json['envelope']),
    );
  }

  /// Create MessageRootStorage from a MessageRoot instance and an id
  factory MessageRootStorage.fromMessageRoot(
    MessageRoot messageRoot,
    IdType id, {
    Uint8List? envelope,
  }) =>
      MessageRootStorage(
        id: id,
        messageSerialized: messageRoot.messageSerialized,
        messageJson: messageRoot.messageJson,
        integrityCheckValue: messageRoot.integrityCheckValue,
        digest: messageRoot.digest,
        envelope: envelope,
      );

  /// Persistence identifier of this stored message.
  @override
  final IdType id;

  /// When the root was stored for retransmission (ms since epoch); drives
  /// the RFC section 10.2 retention window. Null for legacy entries.
  final int? storedAtMs;

  /// Exact bytes of the envelope as first put on the wire; retransmissions
  /// resend them unchanged (RFC section 9.5). Null for legacy entries.
  final Uint8List? envelope;

  static Uint8List? _envelopeFromJson(Object? raw) =>
      raw is String ? const Uint8ListConverter().fromJson(raw) : null;

  /// Serializes this stored message to JSON, including its id.
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'id': id,
      if (storedAtMs != null) 'storedAt': storedAtMs,
      if (envelope case final bytes?)
        'envelope': const Uint8ListConverter().toJson(bytes),
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
    int? storedAtMs,
  }) =>
      MessageRootStorage(
        id: id ?? this.id,
        messageSerialized: messageSerialized ?? this.messageSerialized,
        messageJson: messageJson ?? this.messageJson,
        integrityCheckValue: integrityCheckValue ?? this.integrityCheckValue,
        digest: digest ?? this.digest,
        storedAtMs: storedAtMs ?? this.storedAtMs,
        envelope: envelope,
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
          digest == other.digest &&
          storedAtMs == other.storedAtMs &&
          envelope == other.envelope;

  @override
  int get hashCode =>
      Object.hash(id, messageSerialized, messageJson, integrityCheckValue,
          digest, storedAtMs, envelope);

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
