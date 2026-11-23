import 'dart:async';

import 'package:iermes/iermes.dart';

/// Everything an [ErmesSignalRepublisher] needs.
class ErmesSignalRepublisherInput {
  ErmesSignalRepublisherInput({
    required this.server,
    required this.handler,
    this.localPublicKey,
    this.minInterval = const Duration(seconds: 30),
  });

  final IErmesSignalingServer server;
  final IErmesSignalingHandler<Object?> handler;
  /// Reads our current ECDH public key at each check, so a rotated key
  /// (RFC 8.6) is advertised; `null` (or returning `null`) omits it.
  final String? Function()? localPublicKey;

  /// Minimum time between two publishes (flapping guard).
  final Duration minInterval;
}

/// Publishes a new signal once per NAT mapping change.
class ErmesSignalRepublisher implements IErmesSignalRepublisher {
  ErmesSignalRepublisher._(this._input);

  factory ErmesSignalRepublisher.create(ErmesSignalRepublisherInput input) =>
      ErmesSignalRepublisher._(input);

  final ErmesSignalRepublisherInput _input;
  String? _lastEndpoint;
  DateTime? _lastPublish;
  bool _busy = false;
  Timer? _timer;

  @override
  Future<bool> checkNow() async {
    if (_busy) {
      return false;
    }
    _busy = true;
    try {
      return await _checkAndPublish();
    } finally {
      _busy = false;
    }
  }

  Future<bool> _checkAndPublish() async {
    final signal = await _input.handler.createSignal(
      null,
      _input.localPublicKey?.call(),
      await _input.server.getIdAccount(),
    );
    final endpoint = _endpointOf(signal);
    if (endpoint == _lastEndpoint || _isFlapping()) {
      return false;
    }
    await _input.server.setSignal(signal);
    _lastEndpoint = endpoint;
    _lastPublish = DateTime.now();
    return true;
  }

  bool _isFlapping() {
    final last = _lastPublish;
    return last != null &&
        DateTime.now().difference(last) < _input.minInterval;
  }

  String _endpointOf(ISignalErmes s) =>
      '${s.ipv4}:${s.ipv4Port}|${s.ipv6}:${s.ipv6Port}';

  @override
  void start(Duration interval) {
    stop();
    _timer = Timer.periodic(interval, (_) => unawaited(_safeCheck()));
  }

  Future<void> _safeCheck() async {
    try {
      await checkNow();
    } on Exception {
      // Best-effort: retried at the next tick.
    }
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
