// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_cipher_exchange_base.dart';
import 'nat_config.dart';
import 'nat_test_protocol.dart';

/// `NAT_SCENARIO=rekey`: encrypted heartbeat with a mid-session symmetric-key
/// rotation. The initiator sends [NatTestProtocol.rekeyBeforeMessages] under
/// the original key, rotates (announcing the new key under the OLD key so the
/// peer can still read it, and only switching its encrypt cipher once the peer
/// acknowledges), then sends [NatTestProtocol.rekeyAfterMessages] under the new
/// key. No heartbeat is lost or undecryptable across the boundary.
class NatRekeyExchange extends NatCipherExchangeBase {
  /// Creates the rekey exchange for the given orchestrator, peer, role and tag.
  NatRekeyExchange(
    super.orc,
    super.peer, {
    required super.role,
    required super.tag,
  });

  /// Seq value reserved for the rekey control frame / its ACK.
  static const int rotationSeq = 999999;

  /// Seq values whose ACK has been received.
  final Set<int> _acked = <int>{};

  /// Seq values sent by the initiator.
  final Set<int> _sent = <int>{};

  /// Seq values received by the responder.
  final Set<int> _received = <int>{};

  /// Completes when the peer signals it is ready to exchange.
  final Completer<void> _ready = Completer<void>();

  /// Completes when the peer acknowledges the rotated key.
  final Completer<void> _rotationAck = Completer<void>();

  /// Completes when the end-of-tests marker is received.
  final Completer<void> _finished = Completer<void>();

  /// Number of heartbeats received at the moment the rekey was announced.
  int _receivedBeforeRotation = -1;

  /// Bootstraps, runs the handshake, then drives the initiator or responder
  /// flow depending on the role.
  Future<void> run() async {
    await bootstrap();
    await handshake.run();
    if (isInitiator) {
      await _runInitiator();
    } else {
      await _runResponder();
    }
  }

  @override
  void onExchange(MessageEnvelope env) {
    switch (env.type) {
      case DockerMsgType.ready:
        if (!_ready.isCompleted) {
          _ready.complete();
        }
      case DockerMsgType.ack:
        if (env.seq == rotationSeq) {
          if (!_rotationAck.isCompleted) {
            _rotationAck.complete();
          }
        } else if (env.seq != null) {
          _acked.add(env.seq!);
        }
      case DockerMsgType.testData:
        if (env.seq != null) {
          _received.add(env.seq!);
          unawaited(
            send(MessageEnvelope(type: DockerMsgType.ack, seq: env.seq)),
          );
        }
      case DockerMsgType.newKey:
        _receivedBeforeRotation = _received.length;
        session.registerRotatedDecrypt(env.testName ?? '');
        unawaited(
          send(
            const MessageEnvelope(type: DockerMsgType.ack, seq: rotationSeq),
          ),
        );
      case DockerMsgType.endOfTests:
        if (!_finished.isCompleted) {
          _finished.complete();
        }
      case DockerMsgType.keyExchange:
      case DockerMsgType.decryptReady:
      case DockerMsgType.disconnectNow:
      case DockerMsgType.rendezvousPing:
      case DockerMsgType.rendezvousPong:
      case DockerMsgType.requestMissing:
      case DockerMsgType.keepalive:
        break;
    }
  }

  /// Sends heartbeats under the old key, rotates the key, sends more
  /// heartbeats under the new key, then verifies none were lost at the
  /// boundary before ending the tests.
  Future<void> _runInitiator() async {
    await _ready.future.timeout(NatTestProtocol.readyTimeout);
    final beforeKey = await _sendHeartbeats(
      0,
      NatTestProtocol.rekeyBeforeMessages,
    );
    await _rotateKey();
    final afterKey = await _sendHeartbeats(
      NatTestProtocol.rekeyBeforeMessages,
      NatTestProtocol.rekeyAfterMessages,
    );
    final boundaryFailures = _sent.difference(_acked).length;
    print(
      '[$tag] METRIC: rekey beforeKey=$beforeKey afterKey=$afterKey '
      'boundaryFailures=$boundaryFailures',
    );
    if (boundaryFailures != 0) {
      throw StateError('Lost $boundaryFailures heartbeat(s) across the rekey');
    }
    await send(const MessageEnvelope(type: DockerMsgType.endOfTests));
    await shutdown();
  }

  /// Emits the ready marker, keeps pinging until data flows, waits for the
  /// end-of-tests marker, then verifies heartbeats crossed the rekey boundary.
  Future<void> _runResponder() async {
    print('[$tag] ${NatTestProtocol.cipherReadyMarker} rekey exchange up.');
    final pings = _startReadyPings();
    try {
      await _finished.future.timeout(NatTestProtocol.responderExchangeTimeout);
    } finally {
      pings.cancel();
    }
    _verifyAcrossBoundary();
    print('[$tag] Heartbeats received before and after the rekey.');
    await shutdown();
  }

  /// Sends [count] heartbeats from [start] and waits for every ACK.
  Future<int> _sendHeartbeats(int start, int count) async {
    final target = <int>{};
    for (var i = 0; i < count; i++) {
      final seq = start + i;
      target.add(seq);
      _sent.add(seq);
      await send(
        MessageEnvelope(
          type: DockerMsgType.testData,
          testName: 'hb_$seq',
          seq: seq,
          payload: Uint8List.fromList([seq & 0xff, 0xBE, 0xEF]),
        ),
      );
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    final sw = Stopwatch()..start();
    while (!_acked.containsAll(target)) {
      if (sw.elapsed > NatTestProtocol.ackTimeout) {
        break;
      }
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    return target.where(_acked.contains).length;
  }

  /// Announces the new key under the OLD key, waits for the peer to register
  /// it, then switches the encrypt cipher so later heartbeats use the new key.
  Future<void> _rotateKey() async {
    final newKeyHex = session.rotateEncryptKeyDeferred();
    print('[$tag] Announcing rotated key (under old key)...');
    final sw = Stopwatch()..start();
    while (!_rotationAck.isCompleted) {
      if (sw.elapsed > NatTestProtocol.ackTimeout) {
        throw StateError('Peer never acknowledged the rotated key');
      }
      await send(
        MessageEnvelope(
          type: DockerMsgType.newKey,
          testName: newKeyHex,
          seq: rotationSeq,
        ),
      );
      await Future<void>.delayed(NatTestProtocol.heartbeatInterval);
    }
    session.commitRotatedEncryptKey();
    print('[$tag] Peer acknowledged; encrypt cipher switched to new key.');
  }

  /// Starts a timer that resends `ready` until the first heartbeat arrives.
  Timer _startReadyPings() {
    void ping() {
      if (_received.isNotEmpty) {
        return;
      }
      unawaited(send(const MessageEnvelope(type: DockerMsgType.ready)));
    }

    ping();
    return Timer.periodic(NatTestProtocol.readyResendInterval, (_) => ping());
  }

  /// Asserts EVERY heartbeat crossed the rekey boundary: the full
  /// [rekeyBeforeMessages] + [rekeyAfterMessages] sequence must have arrived
  /// (each frame is decoded only after decryption, so receiving the
  /// post-rotation seqs proves they were decryptable), and at least one must
  /// have arrived before the rotation was announced.
  ///
  /// Note: [registerRotatedDecrypt] adds the new key WITHOUT dropping the old
  /// one (needed for in-flight frames), so this proves the peer can decrypt
  /// after the rotation, not that the sender switched keys — the sender side
  /// enforces the switch via [commitRotatedEncryptKey] and boundaryFailures.
  void _verifyAcrossBoundary() {
    if (_receivedBeforeRotation <= 0) {
      throw StateError('No heartbeats received before the rekey');
    }
    const before = NatTestProtocol.rekeyBeforeMessages;
    const after = NatTestProtocol.rekeyAfterMessages;
    for (var seq = 0; seq < before + after; seq++) {
      if (!_received.contains(seq)) {
        throw StateError('rekey missing heartbeat seq=$seq; received: '
            '$_received');
      }
    }
  }
}

/// Convenience entry point used by the peer binaries.
Future<void> runRekeyScenario(
  IOrcErmes<BookData> orc,
  String peer, {
  required NatRole role,
  required String tag,
}) =>
    NatRekeyExchange(orc, peer, role: role, tag: tag).run();
