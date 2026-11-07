import 'dart:async';

import 'package:iermes/iermes.dart';

import '../repository/ermes_send_repo.dart';
import '../support/exceptions.dart';
import 'ermes_service_version_negotiation.dart';

export 'ermes_version_negotiation_input.dart'
    show ErmesVersionNegotiationOptions;

/// Wires ERMES version negotiation (RFC 7.1) into `ErmesService`: builds the
/// negotiation, sends the adverts and closes the service on failure.
mixin ErmesServiceVersioning {
  /// Id handler used to mint advert ids.
  IIdHandlerService get idHandler;

  /// Send repository adverts and data go through.
  ErmesSendRepo get ermesSendRepo;

  /// Whether the transport is open.
  bool isOpen();

  /// Closes the service.
  void close();

  IErmesVersionNegotiation? _negotiation;

  /// Negotiation of this connection; null when disabled.
  IErmesVersionNegotiation? get versionNegotiation => _negotiation;

  /// Creates the negotiation when [options] is given; call once before the
  /// read repository is built so inbound envelopes are gated from the start.
  IErmesVersionNegotiation? createVersionNegotiation(
    ErmesVersionNegotiationOptions? options,
  ) {
    if (options == null) {
      return null;
    }
    return _negotiation = ErmesVersionNegotiationFactory.create(
      ErmesVersionNegotiationInput(
        sendAdvert: _sendAdvert,
        isOpen: isOpen,
        onFailure: (_) => close(),
        localVersion: options.localVersion,
        timeout: options.timeout,
        resendInterval: options.resendInterval,
      ),
    );
  }

  /// Hooks the negotiation into the send path and starts advertising.
  void startVersionNegotiation() {
    final negotiation = _negotiation;
    if (negotiation == null) {
      return;
    }
    ermesSendRepo.versionNegotiation = negotiation;
    negotiation.start();
  }

  void _sendAdvert(ProtocolVersion version, {required bool ack}) {
    final advert = ServiceMessageVersion(
      id: idHandler.getNewId(),
      version: version,
      ack: ack,
    );
    // A transport closing under us only loses this advert: the next tick
    // (or the timeout) decides the outcome.
    unawaited(
      ermesSendRepo
          .sendMessageType([MessageType.service(advert)])
          .onError<CoreException>((_, __) {}),
    );
  }
}
