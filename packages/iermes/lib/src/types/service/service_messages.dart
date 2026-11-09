
import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../exceptions/ermes_exception.dart';
import '../ermes/message_enums.dart';
import '../ermes/protocol_version.dart';

part 'service_message_acknowledge.dart';
part 'service_message_control.dart';
part 'service_message_gone.dart';
part 'service_message_new_key.dart';
part 'service_message_version.dart';
part 'service_messages.g.dart';

/// Service message for control and coordination
/// Uses sealed class pattern for type-safe message handling by reason
sealed class ServiceMessage implements MessageWithId, IErmesSerializable {
  /// Const base constructor storing the shared message id.
  const ServiceMessage({required this.id});

  /// Builds the matching service message subtype from its `reason` field.
  // MANUAL SERIALIZATION: Polymorphic dispatch on json['reason']
  factory ServiceMessage.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final reason = json['reason'] as String;

    switch (reason) {
      case 'x':
        return ServiceMessageConnectionClose(id: id);
      case 'c':
        return ServiceMessageControl(id: id);
      case 'a':
        return ServiceMessageAcknowledge(
          id: id,
          ackCurrentId: (json['ackCurrentId'] as num?)?.toInt(),
          ackLastReceivedId: (json['ackLastReceivedId'] as num?)?.toInt(),
        );
      case ServiceMessageVersion.reason:
        return ServiceMessageVersion.fromJson(json);
      case 'newkey':
        return ServiceMessageNewKey(
          id: id,
          algorithm: CryptoAlgorithm.values.byName(json['algorithm'] as String),
          key: json['key'] as String,
          start: json['start'] != null
              ? DateTime.parse(json['start'] as String)
              : null,
          expiration: json['expiration'] != null
              ? DateTime.parse(json['expiration'] as String)
              : null,
          startMessage: (json['startMessage'] as num?)?.toInt(),
          endMessage: (json['endMessage'] as num?)?.toInt(),
        );
      case ServiceMessageGone.reason:
        return ServiceMessageGone.fromJson(json);
      default:
        if (json['arrayId'] != null) {
          return ServiceMessageArrayRequest.fromJson(json);
        }
        throw ArgumentError('Unknown service message reason: $reason');
    }
  }

  /// Unique message identifier.
  @override
  final int id;

  /// Serializes this service message to its JSON representation.
  @override
  Map<String, dynamic> toJson();
}
