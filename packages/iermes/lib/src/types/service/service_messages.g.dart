// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceMessageConnectionClose _$ServiceMessageConnectionCloseFromJson(
  Map<String, dynamic> json,
) => ServiceMessageConnectionClose(id: (json['id'] as num).toInt());

Map<String, dynamic> _$ServiceMessageConnectionCloseToJson(
  ServiceMessageConnectionClose instance,
) => <String, dynamic>{'id': instance.id};

ServiceMessageControl _$ServiceMessageControlFromJson(
  Map<String, dynamic> json,
) => ServiceMessageControl(id: (json['id'] as num).toInt());

Map<String, dynamic> _$ServiceMessageControlToJson(
  ServiceMessageControl instance,
) => <String, dynamic>{'id': instance.id};

ServiceMessageAcknowledge _$ServiceMessageAcknowledgeFromJson(
  Map<String, dynamic> json,
) => ServiceMessageAcknowledge(
  id: (json['id'] as num).toInt(),
  ackCurrentId: (json['ackCurrentId'] as num?)?.toInt(),
  ackLastReceivedId: (json['ackLastReceivedId'] as num?)?.toInt(),
);

Map<String, dynamic> _$ServiceMessageAcknowledgeToJson(
  ServiceMessageAcknowledge instance,
) => <String, dynamic>{
  'id': instance.id,
  'ackCurrentId': instance.ackCurrentId,
  'ackLastReceivedId': instance.ackLastReceivedId,
};

ServiceMessageArrayRequest _$ServiceMessageArrayRequestFromJson(
  Map<String, dynamic> json,
) => ServiceMessageArrayRequest(
  id: (json['id'] as num).toInt(),
  arrayId: (json['arrayId'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ServiceMessageArrayRequestToJson(
  ServiceMessageArrayRequest instance,
) => <String, dynamic>{'id': instance.id, 'arrayId': instance.arrayId};
