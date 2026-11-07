import '../exceptions/ermes_exception.dart';
import '../types/ermes/message_type.dart';
import '../types/ermes/protocol_version.dart';
import '../types/service/service_messages.dart';

/// Per-connection ERMES version negotiation (RFC ermes-protocol section 7.1).
///
/// Each side advertises its highest "X.Y" as the first service message.
/// Equal majors adopt the lower minor for the connection lifetime; different
/// majors, or no advert within the fixed timeout, fail the connection
/// permanently with an [ErmesVersionNegotiationException].
abstract class IErmesVersionNegotiation {
  /// Highest version this side advertises.
  ProtocolVersion get localVersion;

  /// Version adopted for the connection; throws
  /// [ErmesVersionNegotiationException] while not negotiated.
  ProtocolVersion get negotiatedVersion;

  /// Whether a compatible version has been adopted.
  bool get isNegotiated;

  /// Whether negotiation failed permanently.
  bool get hasFailed;

  /// Version stamped on outbound envelopes: negotiated, else local.
  ProtocolVersion get envelopeVersion;

  /// Completes once negotiated; completes with an error on failure.
  Future<ProtocolVersion> get ready;

  /// Starts advertising once the transport is open.
  void start();

  /// Handles the counterpart's advert.
  void onAdvert(ServiceMessageVersion advert);

  /// Handles an envelope whose major cannot be parsed (major mismatch).
  void onUnsupportedEnvelope(ProtocolVersion version);

  /// Whether an inbound message stamped [version] may be delivered; waits
  /// for negotiation. False when it is a protocol violation or failed.
  Future<bool> admitInbound(ProtocolVersion version, MessageType message);

  /// Whether an outbound message may be sent; waits for negotiation.
  /// Adverts always pass. False once negotiation failed.
  Future<bool> admitOutbound(MessageType message);

  /// Stops timers; pending waiters see a failure.
  void dispose();
}
