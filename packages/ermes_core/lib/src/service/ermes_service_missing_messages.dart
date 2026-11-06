import 'dart:async';

import 'package:iermes/iermes.dart';

import '../repository/ermes_send_repo.dart';

/// Coordinates the four retransmission paths for [ErmesService]:
/// periodic timer, threshold-based, acknowledge-driven and explicit
/// peer requests. Keeps the timer + threshold logic out of the main
/// service class.
class MissingMessagesController {
  MissingMessagesController({
    required this.controlService,
    required this.sendRepo,
    required this.idHandler,
    required this.threshold,
  });

  final IErmesMessageControlService? controlService;
  final ErmesSendRepo sendRepo;
  final IIdHandlerService idHandler;
  final int? threshold;

  Timer? _interval;

  /// Periodic/threshold/control path (RFC section 9.4): asks the peer,
  /// through a [ServiceMessageArrayRequest], for every inbound id still
  /// missing.
  Future<void> handleMissingMessages() async {
    if (controlService == null) {
      return;
    }
    final ids = await controlService!.idsToRequest();
    if (ids.isNotEmpty) {
      await sendArrayRequest(ids);
    }
  }

  /// Sends one [ServiceMessageArrayRequest] naming the inbound [ids] we lack.
  Future<void> sendArrayRequest(List<IdType> ids) async {
    final msg = ServiceMessageArrayRequest(
      id: idHandler.getNewId(),
      arrayId: List<int>.of(ids),
    );
    await sendRepo.sendMessageType([MessageType.service(msg)]);
  }

  /// Threshold path: invoked after each successfully processed message.
  Future<void> checkAndRequestMissingMessages() async {
    if (controlService == null) {
      return;
    }
    final missing = controlService!.numberOfMissingIds();
    if (threshold != null && missing < threshold!) {
      return;
    }
    await handleMissingMessages();
  }

  /// Acknowledge path: peer reports last id it received; resend the gap.
  void handleAcknowledge(ServiceMessageAcknowledge mess) {
    final lastAcked = mess.ackLastReceivedId;
    if (lastAcked == null) {
      return;
    }
    final ourCurrent = idHandler.getCurrent();
    final gap = ourCurrent - lastAcked - 1;
    if (gap <= 0) {
      return;
    }
    final missing = List.generate(gap, (i) => lastAcked + 1 + i);
    unawaited(sendMissingMessages(missing));
  }

  /// Resends our own outbound [ids]; used when the peer sends an array
  /// request or an acknowledge reveals a gap.
  Future<void> sendMissingMessages(List<IdType> ids) async {
    for (final id in ids) {
      await sendRepo.sendAgain(id);
    }
  }

  void start(int intervalMs) {
    _interval?.cancel();
    _interval = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => handleMissingMessages(),
    );
  }

  void stop() {
    _interval?.cancel();
    _interval = null;
  }
}
