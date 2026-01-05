import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling_types.freezed.dart';
part 'signaling_types.g.dart';

/// Signal data structure for peer signaling
///
/// This represents the SDP (Session Description Protocol) data
/// used in peer connections.
@freezed
class SignalData with _$SignalData {
  const factory SignalData({
    /// SDP type ('offer' or 'answer')
    required String type,

    /// SDP content
    required String sdp,
  }) = _SignalData;

  factory SignalData.fromJson(Map<String, dynamic> json) =>
      _$SignalDataFromJson(json);
}

/// Signal type that supports both SignalData objects and string representations
@freezed
class Signal with _$Signal {
  /// Signal as structured data
  const factory Signal.data(SignalData signalData) = SignalDataType;

  /// Signal as string representation
  const factory Signal.string(String signalString) = SignalStringType;

  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);
}

/// An SDP offer enriched with metadata for reuse
@freezed
class ReusableOffer with _$ReusableOffer {
  const factory ReusableOffer({
    /// SDP content
    required String sdp,

    /// Unique identifier for this offer
    required String offerId,
  }) = _ReusableOffer;

  factory ReusableOffer.fromJson(Map<String, dynamic> json) =>
      _$ReusableOfferFromJson(json);
}

/// An SDP answer enriched with metadata tying it back to an offer
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

  factory ReusableAnswer.fromJson(Map<String, dynamic> json) =>
      _$ReusableAnswerFromJson(json);
}

/// Base response containing peer and connection information
@freezed
class Response with _$Response {
  const factory Response({
    /// Connection identifier
    required String connectionId,

    /// Placeholder for peer instance (implementation-specific)
    /// In Dart, you would typically use your peer implementation here
    Object? peer,
  }) = _Response;

  factory Response.fromJson(Map<String, dynamic> json) =>
      _$ResponseFromJson(json);
}

/// Result of processing an offer and creating an answer
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

  factory OfferResponse.fromJson(Map<String, dynamic> json) =>
      _$OfferResponseFromJson(json);
}

/// Result of processing an answer to finalize a handshake
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

  factory AnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$AnswerResponseFromJson(json);
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
@freezed
class SignalInfoOffer with _$SignalInfoOffer implements ISignalInfo {
  const factory SignalInfoOffer({
    /// The signal data
    required SignalData signalData,

    /// Reusable offer information
    required ReusableOffer reusableOffer,
  }) = _SignalInfoOffer;

  const SignalInfoOffer._();

  factory SignalInfoOffer.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoOfferFromJson(json);

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
@freezed
class SignalInfoAnswer with _$SignalInfoAnswer implements ISignalInfo {
  const factory SignalInfoAnswer({
    /// The signal data
    required SignalData signalData,

    /// Reusable answer information
    required ReusableAnswer reusableAnswer,
  }) = _SignalInfoAnswer;

  const SignalInfoAnswer._();

  factory SignalInfoAnswer.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoAnswerFromJson(json);

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
@freezed
class SignalInfo with _$SignalInfo {
  /// Signal info as an offer
  const factory SignalInfo.offer(SignalInfoOffer offer) = SignalInfoOfferType;

  /// Signal info as an answer
  const factory SignalInfo.answer(SignalInfoAnswer answer) =
      SignalInfoAnswerType;

  factory SignalInfo.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoFromJson(json);
}
