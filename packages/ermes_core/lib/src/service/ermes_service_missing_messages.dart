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
    bool Function()? isOpen,
    this.minRequestInterval = const Duration(milliseconds: 500),
  }) : _isOpen = isOpen ?? _alwaysOpen;

  static bool _alwaysOpen() => true;

  final IErmesMessageControlService? controlService;
  final ErmesSendRepo sendRepo;
  final IIdHandlerService idHandler;
  final int? threshold;

  /// Minimum spacing between two array requests. Every request consumes an
  /// outbound id; unthrottled, requests lost on a dead link open new gaps at
  /// the peer, which requests them back — a request storm across an outage.
  final Duration minRequestInterval;

  /// Whether the link is up; no array request is sent while it is down.
  final bool Function() _isOpen;

  Timer? _interval;

  /// Whether an array request is currently being sent.
  bool _requesting = false;

  /// When the last array request was sent; `null` before the first one.
  DateTime? _lastRequest;

  /// Periodic/threshold/control path (RFC section 9.4): asks the peer,
  /// through a [ServiceMessageArrayRequest], for every inbound id still
  /// missing. Skipped while the link is down, while a request is in flight
  /// or within [minRequestInterval] of the previous one.
  Future<void> handleMissingMessages() async {
    if (controlService == null || !_canRequest()) {
      return;
    }
    _requesting = true;
    try {
      final ids = await controlService!.idsToRequest();
      if (ids.isNotEmpty && _isOpen()) {
        _lastRequest = DateTime.now();
        await sendArrayRequest(ids);
      }
    } finally {
      _requesting = false;
    }
  }

  bool _canRequest() {
    if (_requesting || !_isOpen()) {
      return false;
    }
    final last = _lastRequest;
    return last == null ||
        DateTime.now().difference(last) >= minRequestInterval;
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

  /// Acknowledge path (RFC section 9.2): records the peer's trailing ids
  /// (`ackCurrentId`) as missing, then resends our gap implied by
  /// `ackLastReceivedId`.
  void handleAcknowledge(ServiceMessageAcknowledge mess) {
    final peerCurrent = mess.ackCurrentId;
    if (peerCurrent != null) {
      controlService?.counterpartCurrentId(peerCurrent);
    }
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
  /// request or an acknowledge reveals a gap. Ids no longer held are
  /// reported in a single [ServiceMessageGone] (RFC section 10.2).
  Future<void> sendMissingMessages(List<IdType> ids) async {
    final gone = <IdType>[];
    for (final id in ids) {
      if (!await sendRepo.sendAgain(id)) {
        gone.add(id);
      }
    }
    if (gone.isEmpty) {
      return;
    }
    final msg = ServiceMessageGone(id: idHandler.getNewId(), arrayId: gone);
    await sendRepo.sendMessageType([MessageType.service(msg)]);
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
