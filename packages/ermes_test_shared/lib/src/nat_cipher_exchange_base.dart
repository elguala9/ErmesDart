// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import 'message_envelope.dart';
import 'nat_cipher_handshake.dart';
import 'nat_cipher_session.dart';
import 'nat_config.dart';
import 'nat_rendezvous.dart';
import 'nat_test_protocol.dart';

/// Common lifecycle for the encrypted (P3) scenario engines: generate the
/// ECDH material, install one message handler that splits handshake frames
/// from exchange frames, rendezvous, then run the cipher handshake. Concrete
/// engines implement [onExchange] (per-frame exchange logic) and their own
/// `run` body after calling [bootstrap] + `handshake.run()`.
abstract class NatCipherExchangeBase {
  /// Binds the engine to an orchestrator, peer id, role and log tag.
  NatCipherExchangeBase(
    this.orc,
    this.peer, {
    required this.role,
    required this.tag,
  });

  /// Orchestrator used to send and receive frames.
  final IOrcErmes<BookData> orc;

  /// Remote peer identifier this engine talks to.
  final String peer;

  /// Whether this side is the initiator (A) or responder (B).
  final NatRole role;

  /// Log prefix identifying this engine in verbose output.
  final String tag;

  /// Owns the ECDH key material and cipher registration for this link.
  late final NatCipherSession session = NatCipherSession(peer, tag: tag);

  /// Drives the ECDH handshake using [session] before the exchange begins.
  late final NatCipherHandshake handshake =
      NatCipherHandshake(orc, peer, session, tag: tag);

  /// Whether this engine plays the initiator (role A) side.
  bool get isInitiator => role == NatRole.a;

  /// Generates keys, installs the handler, applies the initiator startup grace
  /// and rendezvous. After this returns, call `handshake.run()`.
  Future<void> bootstrap() async {
    await session.init();
    await _installHandler();
    if (isInitiator) {
      print(
        '[$tag] Startup grace '
        '${NatTestProtocol.initiatorStartupGrace.inSeconds}s...',
      );
      await Future<void>.delayed(NatTestProtocol.initiatorStartupGrace);
    }
    await rendezvous(orc, peer, tag: tag);
  }

  /// Installs the single message handler that filters by peer, splits
  /// handshake frames from exchange frames and dispatches to [onExchange].
  Future<void> _installHandler() async {
    await orc.onMessage((data, from) {
      if (from != peer) {
        return;
      }
      try {
        final env = MessageEnvelope.decode(data);
        if (handshake.handleFrame(env)) {
          return;
        }
        onExchange(env);
      } on Object catch (e) {
        // Pre-handshake frames (arriving before our decrypt cipher is armed)
        // legitimately fail to decode here; a warning, not a failure.
        print('[$tag] WARN: ignored undecodable frame (${data.length}B): $e');
      }
    });
  }

  /// Handles one decrypted exchange frame (testData/ack/ready/newKey/...).
  void onExchange(MessageEnvelope env);

  /// Sends [env] to the peer, encrypted once the cipher is active.
  Future<void> send(MessageEnvelope env) async {
    try {
      await orc.send(env.encode(), peer);
    } on Object catch (e) {
      print('[$tag] send failed: $e');
    }
  }

  /// Flushes and tears down the orchestrator.
  Future<void> shutdown() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await orc.destroy(force: true);
  }
}
