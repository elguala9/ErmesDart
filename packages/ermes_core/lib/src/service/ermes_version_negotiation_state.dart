import 'dart:async';
import 'dart:math';

import 'package:iermes/iermes.dart';

/// Pure negotiation state of one connection (RFC ermes-protocol 7.1):
/// local advert, adopted version and permanent failure. No I/O, no timers.
class ErmesVersionNegotiationState {
  /// Creates the state for a side advertising [localVersion].
  ErmesVersionNegotiationState(this.localVersion) {
    // Failure may happen with nobody waiting: never surface it as unhandled.
    _ready.future.ignore();
  }

  /// Highest version this side advertises.
  final ProtocolVersion localVersion;

  final Completer<ProtocolVersion> _ready = Completer<ProtocolVersion>();
  ProtocolVersion? _negotiated;
  ErmesVersionNegotiationException? _failure;

  /// Completes with the adopted version, or with the failure.
  Future<ProtocolVersion> get ready => _ready.future;

  /// Whether a compatible version has been adopted.
  bool get isNegotiated => _negotiated != null;

  /// The permanent failure, if any.
  ErmesVersionNegotiationException? get failure => _failure;

  /// Whether negotiation failed permanently.
  bool get hasFailed => _failure != null;

  /// Whether the outcome (success or failure) is final.
  bool get isSettled => isNegotiated || hasFailed;

  /// Adopted version; throws [ErmesVersionNegotiationException] otherwise.
  ProtocolVersion get negotiated =>
      _negotiated ??
      (throw _failure ??
          ErmesVersionNegotiationException('Version not negotiated yet'));

  /// Version to stamp on outbound envelopes.
  ProtocolVersion get envelopeVersion => _negotiated ?? localVersion;

  /// Applies the counterpart's advertised [remote] version: equal majors
  /// adopt the lower minor, different majors fail permanently. A repeated
  /// advert after negotiation must agree with the adopted version.
  void resolve(ProtocolVersion remote) {
    if (hasFailed) {
      return;
    }
    if (remote.major != localVersion.major) {
      fail(ErmesVersionMismatchException(
        'Major mismatch: local $localVersion, remote $remote',
      ));
      return;
    }
    final adopted = ProtocolVersion(
      localVersion.major,
      min(localVersion.minor, remote.minor),
    );
    final current = _negotiated;
    if (current == null) {
      _negotiated = adopted;
      _ready.complete(adopted);
    } else if (current != adopted) {
      fail(ErmesVersionMismatchException(
        'Peer re-advertised $remote, negotiated $current',
      ));
    }
  }

  /// Marks negotiation as permanently failed with [error]; idempotent.
  void fail(ErmesVersionNegotiationException error) {
    if (hasFailed) {
      return;
    }
    _failure = error;
    _negotiated = null;
    if (!_ready.isCompleted) {
      _ready.completeError(error);
    }
  }
}
