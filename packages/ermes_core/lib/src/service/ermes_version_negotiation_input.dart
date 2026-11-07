import 'package:iermes/iermes.dart';

/// Fixed time a peer has to announce its ERMES version once the transport
/// is open (RFC ermes-protocol 7.1). Expiry is a permanent failure.
const Duration ermesVersionNegotiationTimeout = Duration(seconds: 10);

/// Default interval between advert retransmissions while unanswered.
const Duration ermesVersionAdvertResendInterval = Duration(milliseconds: 250);

/// Sends a version advert for [version]; [ack] tells the peer that its own
/// advert was already received.
typedef SendVersionAdvert = void Function(
  ProtocolVersion version, {
  required bool ack,
});

/// Everything an [IErmesVersionNegotiation] needs from its connection.
class ErmesVersionNegotiationInput {
  /// Creates the input. [localVersion] defaults to
  /// [ProtocolVersion.current]; [timeout] and [resendInterval] default to
  /// [ermesVersionNegotiationTimeout] and [ermesVersionAdvertResendInterval].
  ErmesVersionNegotiationInput({
    required this.sendAdvert,
    required this.isOpen,
    required this.onFailure,
    this.localVersion,
    Duration? timeout,
    Duration? resendInterval,
  })  : timeout = timeout ?? ermesVersionNegotiationTimeout,
        resendInterval = resendInterval ?? ermesVersionAdvertResendInterval;

  /// Dispatches an advert on the connection.
  final SendVersionAdvert sendAdvert;

  /// Whether the transport is open (adverts are only sent when it is).
  final bool Function() isOpen;

  /// Invoked once when negotiation fails permanently.
  final void Function(ErmesVersionNegotiationException error) onFailure;

  /// Highest version this side advertises; null means current.
  final ProtocolVersion? localVersion;

  /// Time allowed for the counterpart's advert once the transport is open.
  final Duration timeout;

  /// Interval between advert retransmissions.
  final Duration resendInterval;
}

/// Per-service switch for version negotiation. Passing an instance to
/// `ErmesService` enables negotiation; the fields only exist to let tests
/// pretend another version or shorten the fixed timeout.
class ErmesVersionNegotiationOptions {
  /// Creates options; every null field takes its protocol default.
  const ErmesVersionNegotiationOptions({
    this.localVersion,
    this.timeout,
    this.resendInterval,
  });

  /// Highest version advertised; null means [ProtocolVersion.current].
  final ProtocolVersion? localVersion;

  /// Advert timeout; null means [ermesVersionNegotiationTimeout].
  final Duration? timeout;

  /// Advert resend interval; null means [ermesVersionAdvertResendInterval].
  final Duration? resendInterval;
}
