import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling_types.freezed.dart';

/// Signal data structure for peer signaling
///
/// This represents the SDP (Session Description Protocol) data
/// used in peer connections.
@includeInBarrelFile
@freezed
class SignalData with _$SignalData {
  const factory SignalData({
    /// SDP type ('offer' or 'answer')
    required String type,

    /// SDP content
    required String sdp,
  }) = _SignalData;

  factory SignalData.fromJson(Map<String, dynamic> json) {
    return SignalData(
      type: json['type'] as String,
      sdp: json['sdp'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'sdp': sdp,
      };

}

/// Signal type that supports both SignalData objects and string representations
@includeInBarrelFile
@freezed
class Signal with _$Signal {
  /// Signal as structured data
  const factory Signal.data(SignalData signalData) = SignalDataType;

  /// Signal as string representation
  const factory Signal.string(String signalString) = SignalStringType;

  factory Signal.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'data') {
      return Signal.data(SignalData.fromJson(json['data'] as Map<String, dynamic>));
    } else if (json['type'] == 'string') {
      return Signal.string(json['data'] as String);
    } else {
      throw ArgumentError('Unknown signal type');
    }
  }

  Map<String, dynamic> toJson() => when(
        data: (signalData) => {
          'type': 'data',
          'data': signalData.toJson(),
        },
        string: (signalString) => {
          'type': 'string',
          'data': signalString,
        },
      );

}

/// An SDP offer enriched with metadata for reuse
@includeInBarrelFile
@freezed
class ReusableOffer with _$ReusableOffer {
  const factory ReusableOffer({
    /// SDP content
    required String sdp,

    /// Unique identifier for this offer
    required String offerId,
  }) = _ReusableOffer;

  factory ReusableOffer.fromJson(Map<String, dynamic> json) {
    return ReusableOffer(
      sdp: json['sdp'] as String,
      offerId: json['offerId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'sdp': sdp,
        'offerId': offerId,
      };

}

/// An SDP answer enriched with metadata tying it back to an offer
@includeInBarrelFile
@freezed
class ReusableAnswer with _$ReusableAnswer {
  const factory ReusableAnswer({
    /// Unique identifier for this answer
    required String answerId,

    /// Connection identifier
    required String connectionId,

    /// ID of the offer this answers
    required String offerId,

    /// Target peer identifier
    required String targetPeer,
  }) = _ReusableAnswer;

  factory ReusableAnswer.fromJson(Map<String, dynamic> json) {
    return ReusableAnswer(
      answerId: json['answerId'] as String,
      connectionId: json['connectionId'] as String,
      offerId: json['offerId'] as String,
      targetPeer: json['targetPeer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'answerId': answerId,
        'connectionId': connectionId,
        'offerId': offerId,
        'targetPeer': targetPeer,
      };

}

/// Base response containing peer and connection information
@includeInBarrelFile
@freezed
class Response with _$Response {
  const factory Response({
    /// Connection identifier
    required String connectionId,

    /// Placeholder for peer instance (implementation-specific)
    /// In Dart, you would typically use your peer implementation here
    Object? peer,
  }) = _Response;

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      connectionId: json['connectionId'] as String,
      peer: json['peer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        if (peer != null) 'peer': peer,
      };

}

/// Result of processing an offer and creating an answer
@includeInBarrelFile
@freezed
class OfferResponse with _$OfferResponse {
  const factory OfferResponse({
    /// Connection identifier
    required String connectionId,

    /// The generated answer signal
    required SignalInfoAnswer answer,

    /// Peer instance
    Object? peer,
  }) = _OfferResponse;

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    return OfferResponse(
      connectionId: json['connectionId'] as String,
      answer: SignalInfoAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      peer: json['peer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'answer': answer.toJson(),
        if (peer != null) 'peer': peer,
      };

}

/// Result of processing an answer to finalize a handshake
@includeInBarrelFile
@freezed
class AnswerResponse with _$AnswerResponse {
  const factory AnswerResponse({
    /// Connection identifier
    required String connectionId,

    /// Remote peer identifier
    required String remotePeerId,

    /// Peer instance
    Object? peer,
  }) = _AnswerResponse;

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      connectionId: json['connectionId'] as String,
      remotePeerId: json['remotePeerId'] as String,
      peer: json['peer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'connectionId': connectionId,
        'remotePeerId': remotePeerId,
        if (peer != null) 'peer': peer,
      };

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
@freezed
class SignalInfoOffer with _$SignalInfoOffer implements ISignalInfo {
  const factory SignalInfoOffer({
    /// The signal data
    required SignalData signalData,

    /// Reusable offer information
    required ReusableOffer reusableOffer,
  }) = _SignalInfoOffer;

  const SignalInfoOffer._();

  factory SignalInfoOffer.fromJson(Map<String, dynamic> json) {
    return SignalInfoOffer(
      signalData: SignalData.fromJson(json['signalData'] as Map<String, dynamic>),
      reusableOffer: ReusableOffer.fromJson(json['reusableOffer'] as Map<String, dynamic>),
    );
  }

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
}

/// Signal information for an answer
@includeInBarrelFile
@freezed
class SignalInfoAnswer with _$SignalInfoAnswer implements ISignalInfo {
  const factory SignalInfoAnswer({
    /// The signal data
    required SignalData signalData,

    /// Reusable answer information
    required ReusableAnswer reusableAnswer,
  }) = _SignalInfoAnswer;

  const SignalInfoAnswer._();

  factory SignalInfoAnswer.fromJson(Map<String, dynamic> json) {
    return SignalInfoAnswer(
      signalData: SignalData.fromJson(json['signalData'] as Map<String, dynamic>),
      reusableAnswer: ReusableAnswer.fromJson(json['reusableAnswer'] as Map<String, dynamic>),
    );
  }

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
}

/// Union type for signal info (offer or answer)
@includeInBarrelFile
@freezed
class SignalInfo with _$SignalInfo {
  /// Signal info as an offer
  const factory SignalInfo.offer(SignalInfoOffer offer) = SignalInfoOfferType;

  /// Signal info as an answer
  const factory SignalInfo.answer(SignalInfoAnswer answer) =
      SignalInfoAnswerType;

  factory SignalInfo.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>;

    if (type == 'offer') {
      return SignalInfo.offer(SignalInfoOffer.fromJson(data));
    } else if (type == 'answer') {
      return SignalInfo.answer(SignalInfoAnswer.fromJson(data));
    } else {
      throw ArgumentError('Unknown signal info type: $type');
    }
  }

  Map<String, dynamic> toJson() => when(
        offer: (offer) => {
          'type': 'offer',
          'data': offer.toJson(),
        },
        answer: (answer) => {
          'type': 'answer',
          'data': answer.toJson(),
        },
      );

}
