import 'dart:async';

import 'package:iermes/iermes.dart';

import 'ermes_version_negotiation_input.dart';
import 'ermes_version_negotiation_state.dart';

export 'ermes_version_negotiation_input.dart';

/// Drives ERMES version negotiation for one connection (RFC 7.1).
/// Once the transport is open it advertises [localVersion] every resend
/// interval until the counterpart's advert arrives, and answers every
/// un-acked advert with its own. Without a counterpart advert within the
/// fixed timeout (10 s) the connection fails permanently.
class ErmesVersionNegotiation implements IErmesVersionNegotiation {
  /// Creates the negotiation from its [input].
  ErmesVersionNegotiation(this._input)
      : _state = ErmesVersionNegotiationState(
          _input.localVersion ?? ProtocolVersion.current,
        );

  final ErmesVersionNegotiationInput _input;
  final ErmesVersionNegotiationState _state;
  Timer? _ticker;
  DateTime? _deadline;
  bool _reported = false;

  @override
  ProtocolVersion get localVersion => _state.localVersion;

  @override
  ProtocolVersion get negotiatedVersion => _state.negotiated;

  @override
  bool get isNegotiated => _state.isNegotiated;

  @override
  bool get hasFailed => _state.hasFailed;

  @override
  ProtocolVersion get envelopeVersion => _state.envelopeVersion;

  @override
  Future<ProtocolVersion> get ready => _state.ready;

  @override
  void start() {
    _ticker ??= Timer.periodic(_input.resendInterval, (_) => _tick());
    _tick();
  }

  void _tick() {
    if (_state.isSettled) {
      _stopTicker();
      return;
    }
    if (!_input.isOpen()) {
      return;
    }
    final deadline = _deadline ??= DateTime.now().add(_input.timeout);
    if (DateTime.now().isAfter(deadline)) {
      _fail(ErmesVersionNegotiationException(
        'Peer did not announce its ERMES version within ${_input.timeout}',
      ));
      return;
    }
    _input.sendAdvert(localVersion, ack: false);
  }

  @override
  void onAdvert(ServiceMessageVersion advert) {
    if (!advert.ack && !_state.hasFailed && _input.isOpen()) {
      _input.sendAdvert(localVersion, ack: true);
    }
    _state.resolve(advert.version);
    _report();
  }

  @override
  void onUnsupportedEnvelope(ProtocolVersion version) {
    if (_state.isNegotiated) {
      return;
    }
    _fail(ErmesVersionMismatchException(
      'Peer envelope major ${version.major} unsupported (local $localVersion)',
    ));
  }

  @override
  Future<bool> admitInbound(
    ProtocolVersion version,
    MessageType message,
  ) async {
    if (message.asService() is ServiceMessageVersion) {
      return true;
    }
    if (!await _awaitReady()) {
      return false;
    }
    return version == _state.negotiated;
  }

  @override
  Future<bool> admitOutbound(MessageType message) async {
    if (message.asService() is ServiceMessageVersion) {
      return !_state.hasFailed;
    }
    return _awaitReady();
  }

  Future<bool> _awaitReady() => _state.ready.then(
        (_) => !_state.hasFailed,
        onError: (Object _) => false,
      );

  void _fail(ErmesVersionNegotiationException error) {
    _state.fail(error);
    _report();
  }

  /// Stops advertising and notifies the owner of a failure exactly once.
  void _report() {
    _stopTicker();
    final failure = _state.failure;
    if (_reported || failure == null) {
      return;
    }
    _reported = true;
    _input.onFailure(failure);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    _state.fail(ErmesVersionNegotiationException('Connection closed'));
  }
}

/// Factory for [IErmesVersionNegotiation].
class ErmesVersionNegotiationFactory {
  ErmesVersionNegotiationFactory._();
  /// Creates a negotiation bound to the connection described by [input].
  static IErmesVersionNegotiation create(ErmesVersionNegotiationInput input) =>
      ErmesVersionNegotiation(input);
}
