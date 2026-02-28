
import 'package:json_annotation/json_annotation.dart';

part 'signaling_types.g.dart';

/// Signal data structure for peer signaling
///
/// This represents the SDP (Session Description Protocol) data
/// used in peer connections.
@JsonSerializable()
class SignalData {
  const SignalData({
    required this.type,
    required this.sdp,
  });

  factory SignalData.fromJson(Map<String, dynamic> json) =>
      _$SignalDataFromJson(json);

  /// SDP type ('offer' or 'answer')
  final String type;

  /// SDP content
  final String sdp;

  SignalData copyWith({
    String? type,
    String? sdp,
  }) =>
      SignalData(
        type: type ?? this.type,
        sdp: sdp ?? this.sdp,
      );

  Map<String, dynamic> toJson() => _$SignalDataToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalData &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          sdp == other.sdp;

  @override
  int get hashCode => Object.hash(type, sdp);

  @override
  String toString() => 'SignalData(type: $type, sdp: $sdp)';
}

/// Signal type that supports both SignalData objects
/// and string representations using sealed class pattern
sealed class Signal {
  const Signal();

  /// Signal as structured data
  const factory Signal.data(SignalData signalData) = _SignalData;

  /// Signal as string representation
  const factory Signal.string(String signalString) = _SignalString;

  // MANUAL SERIALIZATION: Polymorphic dispatch on json['type']
  factory Signal.fromJson(Map<String, dynamic> json) => switch (json['type']) {
      'data' => Signal.data(
          SignalData.fromJson(
            json['data'] as Map<String, dynamic>,
          ),
        ),
      'string' => Signal.string(json['data'] as String),
      _ => throw ArgumentError('Unknown signal type'),
    };

  // MANUAL SERIALIZATION: Polymorphic dispatch on sealed class
  Map<String, dynamic> toJson() => switch (this) {
        _SignalData(:final signalData) => {
          'type': 'data',
          'data': signalData.toJson(),
        },
        _SignalString(:final signalString) => {
          'type': 'string',
          'data': signalString,
        },
      };
}

class _SignalData extends Signal {
  const _SignalData(this.signalData);
  final SignalData signalData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SignalData &&
          runtimeType == other.runtimeType &&
          signalData == other.signalData;

  @override
  int get hashCode => Object.hash(runtimeType, signalData);

  @override
  String toString() => 'Signal.data($signalData)';
}

class _SignalString extends Signal {
  const _SignalString(this.signalString);
  final String signalString;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SignalString &&
          runtimeType == other.runtimeType &&
          signalString == other.signalString;

  @override
  int get hashCode => Object.hash(runtimeType, signalString);

  @override
  String toString() => 'Signal.string($signalString)';
}

/// Base response containing peer and connection information
class Response {
  const Response({
    required this.connectionId,
    this.peer,
  });

  // MANUAL SERIALIZATION: Object? peer field is opaque
  factory Response.fromJson(Map<String, dynamic> json) =>
      Response(
        connectionId: json['connectionId'] as String,
        peer: json['peer'],
      );

  /// Connection identifier
  final String connectionId;

  /// Placeholder for peer instance (implementation-specific)
  final Object? peer;

  Response copyWith({
    String? connectionId,
    Object? peer,
  }) =>
      Response(
        connectionId: connectionId ?? this.connectionId,
        peer: peer ?? this.peer,
      );

  // MANUAL SERIALIZATION: Object? peer field is opaque
  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        if (peer != null) 'peer': peer,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Response &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          peer == other.peer;

  @override
  int get hashCode => Object.hash(connectionId, peer);

  @override
  String toString() =>
      'Response(connectionId: $connectionId, peer: $peer)';
}

/// Result of processing an offer and creating an answer
class OfferResponse {
  const OfferResponse({
    required this.connectionId,
    required this.answer,
    this.peer,
  });

  // MANUAL SERIALIZATION: Object? peer field is opaque
  factory OfferResponse.fromJson(Map<String, dynamic> json) =>
      OfferResponse(
        connectionId: json['connectionId'] as String,
        answer: SignalInfoAnswer.fromJson(
          json['answer'] as Map<String, dynamic>,
        ),
        peer: json['peer'],
      );

  /// Connection identifier
  final String connectionId;

  /// The generated answer signal
  final SignalInfoAnswer answer;

  /// Peer instance
  final Object? peer;

  OfferResponse copyWith({
    String? connectionId,
    SignalInfoAnswer? answer,
    Object? peer,
  }) =>
      OfferResponse(
        connectionId: connectionId ?? this.connectionId,
        answer: answer ?? this.answer,
        peer: peer ?? this.peer,
      );

  // MANUAL SERIALIZATION: Object? peer field is opaque
  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'answer': answer.toJson(),
        if (peer != null) 'peer': peer,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferResponse &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          answer == other.answer &&
          peer == other.peer;

  @override
  int get hashCode => Object.hash(connectionId, answer, peer);

  @override
  String toString() =>
      'OfferResponse(connectionId: $connectionId, answer: $answer, '
      'peer: $peer)';
}

/// Result of processing an answer to finalize a handshake
class AnswerResponse {
  const AnswerResponse({
    required this.connectionId,
    required this.remotePeerId,
    this.peer,
  });

  // MANUAL SERIALIZATION: Object? peer field is opaque
  factory AnswerResponse.fromJson(Map<String, dynamic> json) =>
      AnswerResponse(
        connectionId: json['connectionId'] as String,
        remotePeerId: json['remotePeerId'] as String,
        peer: json['peer'],
      );

  /// Connection identifier
  final String connectionId;

  /// Remote peer identifier
  final String remotePeerId;

  /// Peer instance
  final Object? peer;

  AnswerResponse copyWith({
    String? connectionId,
    String? remotePeerId,
    Object? peer,
  }) =>
      AnswerResponse(
        connectionId: connectionId ?? this.connectionId,
        remotePeerId: remotePeerId ?? this.remotePeerId,
        peer: peer ?? this.peer,
      );

  // MANUAL SERIALIZATION: Object? peer field is opaque
  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'remotePeerId': remotePeerId,
        if (peer != null) 'peer': peer,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerResponse &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          remotePeerId == other.remotePeerId &&
          peer == other.peer;

  @override
  int get hashCode => Object.hash(connectionId, remotePeerId, peer);

  @override
  String toString() =>
      'AnswerResponse(connectionId: $connectionId, '
      'remotePeerId: $remotePeerId, peer: $peer)';
}

/// Base interface for signal information
abstract class ISignalInfo {
  /// The signal data
  SignalData get signalData;

  /// Check if this is an offer
  bool isOffer();

  /// Check if this is an answer
  bool isAnswer();

  /// Get the signal data
  SignalData getSignalData();
}

/// Signal information for an offer
@JsonSerializable()
class SignalInfoOffer implements ISignalInfo {
  const SignalInfoOffer({
    required this.signalData,
  });

  factory SignalInfoOffer.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoOfferFromJson(json);

  @override
  final SignalData signalData;

  SignalInfoOffer copyWith({
    SignalData? signalData,
  }) =>
      SignalInfoOffer(
        signalData: signalData ?? this.signalData,
      );

  Map<String, dynamic> toJson() => _$SignalInfoOfferToJson(this);

  @override
  bool isOffer() => true;

  @override
  bool isAnswer() => false;

  @override
  SignalData getSignalData() => signalData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalInfoOffer &&
          runtimeType == other.runtimeType &&
          signalData == other.signalData;

  @override
  int get hashCode => Object.hash(runtimeType, signalData);

  @override
  String toString() =>
      'SignalInfoOffer(signalData: $signalData)';
}

/// Signal information for an answer
@JsonSerializable()
class SignalInfoAnswer implements ISignalInfo {
  const SignalInfoAnswer({
    required this.signalData,
  });

  factory SignalInfoAnswer.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoAnswerFromJson(json);

  @override
  final SignalData signalData;

  SignalInfoAnswer copyWith({
    SignalData? signalData,
  }) =>
      SignalInfoAnswer(
        signalData: signalData ?? this.signalData,
      );

  Map<String, dynamic> toJson() => _$SignalInfoAnswerToJson(this);

  @override
  bool isOffer() => false;

  @override
  bool isAnswer() => true;

  @override
  SignalData getSignalData() => signalData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalInfoAnswer &&
          runtimeType == other.runtimeType &&
          signalData == other.signalData;

  @override
  int get hashCode => Object.hash(runtimeType, signalData);

  @override
  String toString() =>
      'SignalInfoAnswer(signalData: $signalData)';
}

/// Union type for signal info (offer or answer) using sealed class
sealed class SignalInfo {
  const SignalInfo();

  /// Signal info as an offer
  const factory SignalInfo.offer(SignalInfoOffer offer) = _SignalInfoOffer;

  /// Signal info as an answer
  const factory SignalInfo.answer(SignalInfoAnswer answer) =
      _SignalInfoAnswer;

  // MANUAL SERIALIZATION: Polymorphic dispatch on json['type']
  factory SignalInfo.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>;

    return switch (type) {
      'offer' => SignalInfo.offer(
          SignalInfoOffer.fromJson(data),
        ),
      'answer' => SignalInfo.answer(
          SignalInfoAnswer.fromJson(data),
        ),
      _ => throw ArgumentError(
          'Unknown signal info type: $type',
        ),
    };
  }

  // MANUAL SERIALIZATION: Polymorphic dispatch on sealed class
  Map<String, dynamic> toJson() => switch (this) {
        _SignalInfoOffer(:final offer) => {
          'type': 'offer',
          'data': offer.toJson(),
        },
        _SignalInfoAnswer(:final answer) => {
          'type': 'answer',
          'data': answer.toJson(),
        },
      };
}

class _SignalInfoOffer extends SignalInfo {
  const _SignalInfoOffer(this.offer);
  final SignalInfoOffer offer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SignalInfoOffer &&
          runtimeType == other.runtimeType &&
          offer == other.offer;

  @override
  int get hashCode => Object.hash(runtimeType, offer);

  @override
  String toString() => 'SignalInfo.offer($offer)';
}

class _SignalInfoAnswer extends SignalInfo {
  const _SignalInfoAnswer(this.answer);
  final SignalInfoAnswer answer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SignalInfoAnswer &&
          runtimeType == other.runtimeType &&
          answer == other.answer;

  @override
  int get hashCode => Object.hash(runtimeType, answer);

  @override
  String toString() => 'SignalInfo.answer($answer)';
}
