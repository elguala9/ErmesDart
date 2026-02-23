// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageData _$MessageDataFromJson(Map<String, dynamic> json) => MessageData(
  id: (json['id'] as num).toInt(),
  data: _uint8ListFromJson(json['data'] as String),
);

Map<String, dynamic> _$MessageDataToJson(MessageData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': _uint8ListToJson(instance.data),
    };

ChunkMessage _$ChunkMessageFromJson(Map<String, dynamic> json) => ChunkMessage(
  id: (json['id'] as num).toInt(),
  data: _uint8ListFromJson(json['data'] as String),
  refId: json['refId'] as String,
  index: (json['index'] as num).toInt(),
  roof: (json['roof'] as num).toInt(),
);

Map<String, dynamic> _$ChunkMessageToJson(ChunkMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'data': _uint8ListToJson(instance.data),
      'refId': instance.refId,
      'index': instance.index,
      'roof': instance.roof,
    };

ChunkInfo _$ChunkInfoFromJson(Map<String, dynamic> json) => ChunkInfo(
  chunkId: (json['chunkId'] as num).toInt(),
  index: (json['index'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ChunkInfoToJson(ChunkInfo instance) => <String, dynamic>{
  'chunkId': instance.chunkId,
  'index': instance.index,
};
