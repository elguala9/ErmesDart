part of 'service_messages.dart';

/// New key exchange message (reason: 'newkey')
/// Distributes encryption key material with validity windows
final class ServiceMessageNewKey extends ServiceMessage {
  /// Creates a key-exchange message carrying key material and validity window.
  const ServiceMessageNewKey({
    required super.id,
    required this.algorithm,
    required this.key,
    this.start,
    this.expiration,
    this.startMessage,
    this.endMessage,
  });

  /// Cryptographic algorithm for this key
  final CryptoAlgorithm algorithm;

  /// The key material as string
  final String key;

  /// When this key becomes valid
  final DateTime? start;

  /// When this key expires
  final DateTime? expiration;

  /// First message ID this key applies to
  final int? startMessage;

  /// Last message ID this key applies to
  final int? endMessage;

  /// Returns a copy of this key message with the given fields replaced.
  ServiceMessageNewKey copyWith({
    int? id,
    CryptoAlgorithm? algorithm,
    String? key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  }) =>
      ServiceMessageNewKey(
        id: id ?? this.id,
        algorithm: algorithm ?? this.algorithm,
        key: key ?? this.key,
        start: start ?? this.start,
        expiration: expiration ?? this.expiration,
        startMessage: startMessage ?? this.startMessage,
        endMessage: endMessage ?? this.endMessage,
      );

  // MANUAL SERIALIZATION: DateTime + CryptoAlgorithm converters
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': 'newkey',
        'algorithm': algorithm.name,
        'key': key,
        if (start != null) 'start': start!.toIso8601String(),
        if (expiration != null) 'expiration': expiration!.toIso8601String(),
        if (startMessage != null) 'startMessage': startMessage,
        if (endMessage != null) 'endMessage': endMessage,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageNewKey &&
          id == other.id &&
          algorithm == other.algorithm &&
          key == other.key &&
          start == other.start &&
          expiration == other.expiration &&
          startMessage == other.startMessage &&
          endMessage == other.endMessage;

  @override
  int get hashCode => Object.hash(
        id,
        algorithm,
        key,
        start,
        expiration,
        startMessage,
        endMessage,
      );

  @override
  String toString() {
    final keyPreview = key.substring(0, (key.length ~/ 4).clamp(0, 8));
    return 'ServiceMessageNewKey(id: $id, algorithm: $algorithm, '
        'key: $keyPreview..., start: $start, expiration: $expiration, '
        'startMessage: $startMessage, endMessage: $endMessage)';
  }
}
