part of 'service_messages.dart';

/// ERMES version advert (reason: 'v'), RFC ermes-protocol section 7.1.
///
/// The first service message each peer sends on a new connection carries
/// the single highest "X.Y" the sender supports. [ack] is true when the
/// sender has already received the counterpart's advert, so the receiver
/// does not need to answer it with its own advert.
final class ServiceMessageVersion extends ServiceMessage {
  /// Creates a version advert for [version].
  const ServiceMessageVersion({
    required super.id,
    required this.version,
    this.ack = false,
  });

  /// Builds a [ServiceMessageVersion] from JSON; throws
  /// [ErmesSerializationException] when `version` is absent or malformed.
  factory ServiceMessageVersion.fromJson(Map<String, dynamic> json) {
    final raw = json['version'];
    if (raw == null) {
      throw ErmesSerializationException('Version advert without "version"');
    }
    final ack = json['ack'];
    return ServiceMessageVersion(
      id: (json['id'] as num).toInt(),
      version: ProtocolVersion.parse(raw),
      ack: ack is bool && ack,
    );
  }

  /// Wire value of the `reason` field.
  static const String reason = 'v';

  /// Highest version the sender supports.
  final ProtocolVersion version;

  /// Whether the sender already holds the receiver's advert.
  final bool ack;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': reason,
        'version': version.toString(),
        'ack': ack,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMessageVersion &&
          id == other.id &&
          version == other.version &&
          ack == other.ack;

  @override
  int get hashCode => Object.hash(id, version, ack);

  @override
  String toString() =>
      'ServiceMessageVersion(id: $id, version: $version, ack: $ack)';
}
