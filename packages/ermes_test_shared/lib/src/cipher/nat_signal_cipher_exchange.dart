// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_test_protocol.dart';
import '../config/nat_config.dart';
import '../config/nat_rendezvous.dart';
import '../config/nat_verbose.dart';

part 'nat_signal_cipher_exchange_frames.dart';

/// `NAT_SCENARIO=signal-cipher`: proves the connection is encrypted using ONLY
/// the ECDH public key carried in the signal.
///
/// Unlike [NatEncryptedExchange], this engine runs NO in-band cipher handshake
/// (`NatCipherSession`/`NatCipherHandshake`). It relies entirely on the
/// production path in `OrcConnectionOpener`: `createSignal` advertises the
/// local ECDH public key and `_applySharedSecret` derives the shared cipher
/// from the peer's signal on every (re)dial. After rendezvous it asserts a
/// real encrypt cipher is registered for the peer, then exchanges an encrypted
/// burst - every ACK proves both sides derived the SAME secret off the wire.
class NatSignalCipherExchange {
  /// Creates the signal-cipher exchange for the given orchestrator, peer,
  /// role and tag.
  NatSignalCipherExchange(
    this.orc,
    this.peer, {
    required this.role,
    required this.tag,
  });

  /// Orchestrator driving the connection and message exchange.
  final IOrcErmes<BookData> orc;

  /// Pubkey of the remote peer.
  final String peer;

  /// Role (initiator or responder) this side plays.
  final NatRole role;

  /// Log tag identifying this peer in stdout.
  final String tag;

  /// Seq values whose ACK has been received.
  final Set<int> _acked = <int>{};

  /// Seq values received by the responder.
  final Set<int> _received = <int>{};

  /// Completes when the peer signals it is ready to exchange.
  final Completer<void> _ready = Completer<void>();

  /// Completes when every message has been acknowledged.
  final Completer<void> _done = Completer<void>();

  /// Completes when the end-of-tests marker is received.
  final Completer<void> _finished = Completer<void>();

  /// Whether this side is the initiator (role A).
  bool get _isInitiator => role == NatRole.a;

  /// Installs the handler, rendezvous with the peer, asserts the signal-derived
  /// cipher is active, then drives the initiator or responder flow.
  Future<void> run() async {
    await _installHandler();
    if (_isInitiator) {
      await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);
    }
    await rendezvous(orc, peer, tag: tag);
    _assertSignalCipherActive();
    if (_isInitiator) {
      await _runInitiator();
    } else {
      await _runResponder();
    }
  }

  /// Encodes and sends [env] to the peer, swallowing transient send errors.
  Future<void> send(MessageEnvelope env) async {
    try {
      await orc.send(env.encode(), peer);
    } on Object catch (e) {
      print('[$tag] send failed: $e');
    }
  }

  /// Waits for the peer ready, sends the encrypted burst, waits for all ACKs,
  /// verifies them, reports the metric and ends the tests.
  Future<void> _runInitiator() async {
    print('[$tag] Signal cipher active; waiting for peer ready...');
    await _ready.future.timeout(NatTestProtocol.readyTimeout);
    await _sendBurst();
    await _done.future.timeout(NatTestProtocol.ackTimeout);
    _verify(_acked, 'ACK');
    // Every ack proves the peer decoded (i.e. decrypted) a testData, so
    // `messages == messageCount` (enforced by _verify above) IS the decrypt
    // proof - no separate tautological `decryptOk` flag.
    print(
      '[$tag] METRIC: signal-cipher signalCipher=true '
      'messages=${_acked.length}',
    );
    await send(const MessageEnvelope(type: DockerMsgType.endOfTests));
    await _shutdown();
  }

  /// Pings ready until data flows, waits for the full sequence plus the
  /// end-of-tests marker, then verifies everything was received.
  Future<void> _runResponder() async {
    final pings = _startReadyPings();
    try {
      await _finished.future.timeout(
        NatTestProtocol.responderExchangeTimeout,
      );
    } finally {
      pings.cancel();
    }
    _verify(_received, 'testData');
    print('[$tag] Signal-encrypted sequence received and acknowledged.');
    await _shutdown();
  }

  /// Waits briefly for in-flight frames, then force-destroys the orchestrator.
  Future<void> _shutdown() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await orc.destroy(force: true);
  }
}

/// Convenience entry point used by the peer binaries.
Future<void> runSignalCipherScenario(
  IOrcErmes<BookData> orc,
  String peer, {
  required NatRole role,
  required String tag,
}) =>
    NatSignalCipherExchange(orc, peer, role: role, tag: tag).run();
