part of 'service_messages.dart';

/// Encryption public-key rotation (reason: 'newpubkey'), RFC section 8.6.
///
/// Announces the sender's new ECDH public key in-band. It carries only
/// public material and may be sent in the clear.
final class ServiceMessageNewPubKey extends ServiceMessage {
  /// Creates a newpubkey message carrying the new public [key].
  const ServiceMessageNewPubKey({required super.id, required this.key});

  /// Builds a [ServiceMessageNewPubKey] from its JSON representation.
  factory ServiceMessageNewPubKey.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw ArgumentError('newpubkey requires a non-empty "key"');
    }
    final id = json['id'];
    if (id is! num) {
      throw ArgumentError('newpubkey requires a numeric "id"');
    }
    return ServiceMessageNewPubKey(id: id.toInt(), key: key);
  }

  /// Wire value of the `reason` field.
  static const String reason = 'newpubkey';

  /// The sender's new encryption public key.
  final String key;

  /// Serializes this message to JSON, tagging it with reason 'newpubkey'.
  @override
  Map<String, dynamic> toJson() => {'id': id, 'reason': reason, 'key': key};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageNewPubKey && id == other.id && key == other.key;

  @override
  int get hashCode => Object.hash(id, key);

  @override
  String toString() => 'ServiceMessageNewPubKey(id: $id, key: $key)';
}
