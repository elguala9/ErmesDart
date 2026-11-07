import 'package:iermes/iermes.dart';

import '../support/ermes_receive_stats.dart';

/// Decides whether an inbound envelope stamped [version] carrying [message]
/// may be processed (RFC ermes-protocol 7.1).
///
/// Non-advert envelopes wait for negotiation; a `v` different from the
/// negotiated version is a protocol violation and the envelope is dropped.
Future<bool> admitEnvelope(
  IErmesVersionNegotiation negotiation,
  ProtocolVersion version,
  InternalMessage message,
) async {
  final admitted = await negotiation.admitInbound(version, message.message);
  if (!admitted) {
    ErmesReceiveStats.active?.onDropVersion(
      ErmesVersionNegotiationException(
        'Protocol violation: envelope v=$version on a connection that did '
        'not negotiate it',
      ),
    );
  }
  return admitted;
}
