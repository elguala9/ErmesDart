import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// Signal data structure for peer signaling
///
/// This represents the SDP (Session Description Protocol) data
/// used in peer connections.
@includeInBarrelFile
class SignalData {
  const SignalData({
    required this.type,
    required this.sdp,
  });

  factory SignalData.fromJson(Map<String, dynamic> json) =>
      SignalData(
        type: json['type'] as String,
        sdp: json['sdp'] as String,
      );

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

  Map<String, dynamic> toJson() => {
        'type': type,
        'sdp': sdp,
      };

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
@includeInBarrelFile
sealed class Signal {
  const Signal();

  /// Signal as structured data
  const factory Signal.data(SignalData signalData) = _SignalData;

  /// Signal as string representation
  const factory Signal.string(String signalString) = _SignalString;

  factory Signal.fromJson(Map<String, dynamic> json) => switch (json['type']) {
      'data' => Signal.data(
          SignalData.fromJson(
            json['data'] as Map<String, dynamic>,
          ),
        ),
      'string' => Signal.string(json['data'] as String),
      _ => throw ArgumentError('Unknown signal type'),
    };

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

/// An SDP offer enriched with metadata for reuse
@includeInBarrelFile
class ReusableOffer {
  const ReusableOffer({
    required this.sdp,
    required this.offerId,
  });

  factory ReusableOffer.fromJson(Map<String, dynamic> json) =>
      ReusableOffer(
        sdp: json['sdp'] as String,
        offerId: json['offerId'] as String,
      );

  /// SDP content
  final String sdp;

  /// Unique identifier for this offer
  final String offerId;

  ReusableOffer copyWith({
    String? sdp,
    String? offerId,
  }) =>
      ReusableOffer(
        sdp: sdp ?? this.sdp,
        offerId: offerId ?? this.offerId,
      );

  Map<String, dynamic> toJson() => {
        'sdp': sdp,
        'offerId': offerId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReusableOffer &&
          runtimeType == other.runtimeType &&
          sdp == other.sdp &&
          offerId == other.offerId;

  @override
  int get hashCode => Object.hash(sdp, offerId);

  @override
  String toString() =>
      'ReusableOffer(sdp: $sdp, offerId: $offerId)';
}

/// An SDP answer enriched with metadata tying it back to an offer
@includeInBarrelFile
class ReusableAnswer {
  const ReusableAnswer({
    required this.answerId,
    required this.connectionId,
    required this.offerId,
    required this.targetPeer,
  });

  factory ReusableAnswer.fromJson(Map<String, dynamic> json) =>
      ReusableAnswer(
        answerId: json['answerId'] as String,
        connectionId: json['connectionId'] as String,
        offerId: json['offerId'] as String,
        targetPeer: json['targetPeer'] as String,
      );

  /// Unique identifier for this answer
  final String answerId;

  /// Connection identifier
  final String connectionId;

  /// ID of the offer this answers
  final String offerId;

  /// Target peer identifier
  final String targetPeer;

  ReusableAnswer copyWith({
    String? answerId,
    String? connectionId,
    String? offerId,
    String? targetPeer,
  }) =>
      ReusableAnswer(
        answerId: answerId ?? this.answerId,
        connectionId: connectionId ?? this.connectionId,
        offerId: offerId ?? this.offerId,
        targetPeer: targetPeer ?? this.targetPeer,
      );

  Map<String, dynamic> toJson() => {
        'answerId': answerId,
        'connectionId': connectionId,
        'offerId': offerId,
        'targetPeer': targetPeer,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReusableAnswer &&
          runtimeType == other.runtimeType &&
          answerId == other.answerId &&
          connectionId == other.connectionId &&
          offerId == other.offerId &&
          targetPeer == other.targetPeer;

  @override
  int get hashCode =>
      Object.hash(answerId, connectionId, offerId, targetPeer);

  @override
  String toString() =>
      'ReusableAnswer(answerId: $answerId, connectionId: $connectionId, '
      'offerId: $offerId, targetPeer: $targetPeer)';
}

/// Base response containing peer and connection information
@includeInBarrelFile
class Response {
  const Response({
    required this.connectionId,
    this.peer,
  });

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
@includeInBarrelFile
class OfferResponse {
  const OfferResponse({
    required this.connectionId,
    required this.answer,
    this.peer,
  });

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
@includeInBarrelFile
class AnswerResponse {
  const AnswerResponse({
    required this.connectionId,
    required this.remotePeerId,
    this.peer,
  });

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
@includeInBarrelFile
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
@includeInBarrelFile
class SignalInfoOffer implements ISignalInfo {
  const SignalInfoOffer({
    required this.signalData,
    required this.reusableOffer,
  });

  factory SignalInfoOffer.fromJson(Map<String, dynamic> json) =>
      SignalInfoOffer(
        signalData: SignalData.fromJson(
          json['signalData'] as Map<String, dynamic>,
        ),
        reusableOffer: ReusableOffer.fromJson(
          json['reusableOffer']
              as Map<String, dynamic>,
        ),
      );

  @override
  final SignalData signalData;

  final ReusableOffer reusableOffer;

  SignalInfoOffer copyWith({
    SignalData? signalData,
    ReusableOffer? reusableOffer,
  }) =>
      SignalInfoOffer(
        signalData: signalData ?? this.signalData,
        reusableOffer: reusableOffer ?? this.reusableOffer,
      );

  Map<String, dynamic> toJson() => {
        'signalData': signalData.toJson(),
        'reusableOffer': reusableOffer.toJson(),
      };

  @override
  bool isOffer() => true;

  @override
  bool isAnswer() => false;

  @override
  SignalData getSignalData() => signalData;

  /// Get the offer information
  ReusableOffer getOfferInfo() => reusableOffer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalInfoOffer &&
          runtimeType == other.runtimeType &&
          signalData == other.signalData &&
          reusableOffer == other.reusableOffer;

  @override
  int get hashCode => Object.hash(signalData, reusableOffer);

  @override
  String toString() =>
      'SignalInfoOffer(signalData: $signalData, '
      'reusableOffer: $reusableOffer)';
}

/// Signal information for an answer
@includeInBarrelFile
class SignalInfoAnswer implements ISignalInfo {
  const SignalInfoAnswer({
    required this.signalData,
    required this.reusableAnswer,
  });

  factory SignalInfoAnswer.fromJson(Map<String, dynamic> json) =>
      SignalInfoAnswer(
        signalData: SignalData.fromJson(
          json['signalData'] as Map<String, dynamic>,
        ),
        reusableAnswer: ReusableAnswer.fromJson(
          json['reusableAnswer']
              as Map<String, dynamic>,
        ),
      );

  @override
  final SignalData signalData;

  final ReusableAnswer reusableAnswer;

  SignalInfoAnswer copyWith({
    SignalData? signalData,
    ReusableAnswer? reusableAnswer,
  }) =>
      SignalInfoAnswer(
        signalData: signalData ?? this.signalData,
        reusableAnswer: reusableAnswer ?? this.reusableAnswer,
      );

  Map<String, dynamic> toJson() => {
        'signalData': signalData.toJson(),
        'reusableAnswer': reusableAnswer.toJson(),
      };

  @override
  bool isOffer() => false;

  @override
  bool isAnswer() => true;

  @override
  SignalData getSignalData() => signalData;

  /// Get the answer information
  ReusableAnswer getAnswerInfo() => reusableAnswer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalInfoAnswer &&
          runtimeType == other.runtimeType &&
          signalData == other.signalData &&
          reusableAnswer == other.reusableAnswer;

  @override
  int get hashCode => Object.hash(signalData, reusableAnswer);

  @override
  String toString() =>
      'SignalInfoAnswer(signalData: $signalData, '
      'reusableAnswer: $reusableAnswer)';
}

/// Union type for signal info (offer or answer) using sealed class
@includeInBarrelFile
sealed class SignalInfo {
  const SignalInfo();

  /// Signal info as an offer
  const factory SignalInfo.offer(SignalInfoOffer offer) = _SignalInfoOffer;

  /// Signal info as an answer
  const factory SignalInfo.answer(SignalInfoAnswer answer) =
      _SignalInfoAnswer;

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
