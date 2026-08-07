// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ermes_signaling/ermes_signaling.dart' show BookData;
import 'package:iermes/iermes.dart';

import '../bootstrap/message_envelope.dart';
import '../bootstrap/nat_test_protocol.dart';
import 'nat_cipher_session.dart';

/// Race-free ECDH handshake shared by the encrypted and rekey scenarios.
///
/// Each peer advertises its ECDH public key, registers the derived cipher for
/// DECRYPTION first, then announces `decryptReady`. Only once the peer has
/// confirmed it can decrypt does this side enable its ENCRYPT cipher — so no
/// peer ever sends ciphertext the other cannot yet read. The owning engine
/// feeds inbound frames through [handleFrame] from its single message handler.
class NatCipherHandshake {
  /// Binds the handshake to its orchestrator, peer, cipher session and tag.
  NatCipherHandshake(this._orc, this._peer, this._session, {required this.tag});

  final IOrcErmes<BookData> _orc;
  final String _peer;
  final NatCipherSession _session;

  /// Log prefix identifying this handshake in verbose output.
  final String tag;

  String? _peerPub;
  bool _peerDecryptReady = false;

  /// Routes one inbound frame; returns true when it was a handshake frame and
  /// should not be processed further by the exchange.
  bool handleFrame(MessageEnvelope env) {
    switch (env.type) {
      case DockerMsgType.keyExchange:
        _peerPub ??= env.testName;
        return true;
      case DockerMsgType.decryptReady:
        _peerDecryptReady = true;
        return true;
      // Rendezvous liveness frames belong to the rendezvous handler, not the
      // exchange: consume them so onExchange never sees them.
      case DockerMsgType.rendezvousPing:
      case DockerMsgType.rendezvousPong:
        return true;
      // Every non-handshake frame is the exchange's to handle.
      case DockerMsgType.ready:
      case DockerMsgType.testData:
      case DockerMsgType.ack:
      case DockerMsgType.disconnectNow:
      case DockerMsgType.endOfTests:
      case DockerMsgType.newKey:
      case DockerMsgType.requestMissing:
      case DockerMsgType.keepalive:
        return false;
    }
  }

  /// Drives the handshake to completion (both sides can encrypt) or throws
  /// once [NatTestProtocol.handshakeBudget] elapses.
  Future<void> run() async {
    print('[$tag] Cipher handshake: exchanging ECDH public keys...');
    final sw = Stopwatch()..start();
    var linger = 0;
    while (true) {
      if (sw.elapsed > NatTestProtocol.handshakeBudget) {
        throw StateError(
          'Cipher handshake did not complete within '
          '${NatTestProtocol.handshakeBudget.inSeconds}s',
        );
      }
      // Advertise our key until the peer has derived its cipher: its
      // decryptReady implies it already received our key.
      if (!_peerDecryptReady) {
        await _send(
          MessageEnvelope(
            type: DockerMsgType.keyExchange,
            testName: _session.publicKey,
          ),
        );
      }
      final peerPub = _peerPub;
      if (peerPub != null) {
        _session.registerDecrypt(peerPub);
      }
      if (_session.decryptReady) {
        await _send(const MessageEnvelope(type: DockerMsgType.decryptReady));
      }
      if (_session.decryptReady && _peerDecryptReady) {
        _session.enableEncrypt();
      }
      if (_session.encryptReady) {
        linger++;
        if (linger >= NatTestProtocol.handshakeLingerFrames) {
          print('[$tag] Cipher handshake complete.');
          return;
        }
      }
      await Future<void>.delayed(NatTestProtocol.handshakeFrameInterval);
    }
  }

  /// Sends a handshake frame, swallowing transient send errors while the
  /// link is still settling.
  Future<void> _send(MessageEnvelope env) async {
    try {
      await _orc.send(env.encode(), _peer);
    } on Object catch (e) {
      print('[$tag] handshake frame send failed (link settling?): $e');
    }
  }
}
