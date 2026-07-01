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
import 'nat_verbose.dart';

/// `NAT_SCENARIO=encrypted`: ECDH handshake over the punched link, then an
/// encrypted burst of [NatTestProtocol.messageCount] messages. The initiator
/// asserts the on-wire bytes are ciphertext and that every message was
/// decrypted (each ACK matches the plaintext sequence).
class NatEncryptedExchange extends NatCipherExchangeBase {
  /// Creates the encrypted-scenario engine for the given peer and role.
  NatEncryptedExchange(
    super.orc,
    super.peer, {
    required super.role,
    required super.tag,
  });

  final Set<int> _acked = <int>{};
  final Set<int> _received = <int>{};
  final Completer<void> _ready = Completer<void>();
  final Completer<void> _done = Completer<void>();
  final Completer<void> _finished = Completer<void>();

  /// Runs the full scenario: bootstrap, cipher handshake, then the
  /// initiator or responder exchange depending on [role].
  Future<void> run() async {
    await bootstrap();
    await handshake.run();
    if (isInitiator) {
      await _runInitiator();
    } else {
      await _runResponder();
    }
  }

  /// Handles one decrypted exchange frame, tracking ready/ack/testData and
  /// end-of-tests signals and echoing acks for received data.
  @override
  void onExchange(MessageEnvelope env) {
    switch (env.type) {
      case DockerMsgType.ready:
        if (!_ready.isCompleted) {
          _ready.complete();
        }
      case DockerMsgType.ack:
        if (env.seq != null) {
          _acked.add(env.seq!);
          if (_acked.length >= NatTestProtocol.messageCount &&
              !_done.isCompleted) {
            _done.complete();
          }
        }
      case DockerMsgType.testData:
        if (env.seq != null) {
          _received.add(env.seq!);
          unawaited(
            send(MessageEnvelope(type: DockerMsgType.ack, seq: env.seq)),
          );
        }
      case DockerMsgType.endOfTests:
        if (!_finished.isCompleted) {
          _finished.complete();
        }
      case DockerMsgType.keyExchange:
      case DockerMsgType.decryptReady:
      case DockerMsgType.disconnectNow:
      case DockerMsgType.newKey:
      case DockerMsgType.rendezvousPing:
      case DockerMsgType.rendezvousPong:
      case DockerMsgType.requestMissing:
      case DockerMsgType.keepalive:
        break;
    }
  }

  /// Waits for the peer to be ready, sends the encrypted burst, verifies all
  /// acks arrived and that ciphertext was on the wire, then shuts down.
  Future<void> _runInitiator() async {
    final sw = Stopwatch()..start();
    print('[$tag] Cipher ready; waiting for peer ready...');
    await _ready.future.timeout(NatTestProtocol.readyTimeout);
    final ciphertextOnWire = await _sendBurst();
    await _done.future.timeout(NatTestProtocol.ackTimeout);
    _verify(_acked, 'ACK');
    final decryptOk = _acked.length == NatTestProtocol.messageCount;
    print(
      '[$tag] METRIC: encrypted handshakeMs=${sw.elapsedMilliseconds} '
      'messages=${_acked.length} ciphertextOnWire=$ciphertextOnWire '
      'decryptOk=$decryptOk',
    );
    if (!ciphertextOnWire) {
      throw StateError('Cipher did not produce ciphertext on the wire');
    }
    await send(const MessageEnvelope(type: DockerMsgType.endOfTests));
    await shutdown();
  }

  /// Periodically advertises readiness, waits for the full sequence and
  /// end-of-tests, verifies every message arrived, then shuts down.
  Future<void> _runResponder() async {
    print('[$tag] ${NatTestProtocol.cipherReadyMarker} encrypted exchange up.');
    final pings = _startReadyPings();
    try {
      await _finished.future.timeout(
        NatTestProtocol.responderExchangeTimeout,
      );
    } finally {
      pings.cancel();
    }
    _verify(_received, 'testData');
    print('[$tag] Encrypted sequence received and acknowledged.');
    await shutdown();
  }

  /// Sends the encrypted burst; returns true when the cipher demonstrably
  /// turns the plaintext envelope into ciphertext (the transform the wire
  /// carries).
  Future<bool> _sendBurst() async {
    var ciphertextOnWire = true;
    for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
      final env = MessageEnvelope(
        type: DockerMsgType.testData,
        testName: 'enc_$seq',
        seq: seq,
        payload: Uint8List.fromList([seq, seq + 1, seq + 2, 0xCA, 0xFE]),
      );
      if (seq == 0) {
        ciphertextOnWire = session.producesCiphertextFor(env.encode());
      }
      await send(env);
      print('[$tag] >> SENT (encrypted) ${env.describe()} '
          'to=${shortId(peer)}');
    }
    return ciphertextOnWire;
  }

  /// Starts a timer that repeatedly sends `ready` frames until the first
  /// data frame is received, returning the timer so it can be cancelled.
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

  /// Asserts [got] contains every sequence number 0..messageCount-1,
  /// throwing a [StateError] describing the first gap or count mismatch.
  void _verify(Set<int> got, String what) {
    for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
      if (!got.contains(seq)) {
        throw StateError('Missing $what seq=$seq; got: $got');
      }
    }
    if (got.length != NatTestProtocol.messageCount) {
      throw StateError(
        'Expected ${NatTestProtocol.messageCount} $what, got ${got.length}',
      );
    }
  }
}

/// Convenience entry point used by the peer binaries.
Future<void> runEncryptedScenario(
  IOrcErmes<BookData> orc,
  String peer, {
  required NatRole role,
  required String tag,
}) =>
    NatEncryptedExchange(orc, peer, role: role, tag: tag).run();
