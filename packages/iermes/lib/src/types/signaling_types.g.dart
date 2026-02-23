// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signaling_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalData _$SignalDataFromJson(Map<String, dynamic> json) =>
    SignalData(type: json['type'] as String, sdp: json['sdp'] as String);

Map<String, dynamic> _$SignalDataToJson(SignalData instance) =>
    <String, dynamic>{'type': instance.type, 'sdp': instance.sdp};

SignalInfoOffer _$SignalInfoOfferFromJson(Map<String, dynamic> json) =>
    SignalInfoOffer(
      signalData: SignalData.fromJson(
        json['signalData'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SignalInfoOfferToJson(SignalInfoOffer instance) =>
    <String, dynamic>{'signalData': instance.signalData};

SignalInfoAnswer _$SignalInfoAnswerFromJson(Map<String, dynamic> json) =>
    SignalInfoAnswer(
      signalData: SignalData.fromJson(
        json['signalData'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SignalInfoAnswerToJson(SignalInfoAnswer instance) =>
    <String, dynamic>{'signalData': instance.signalData};
