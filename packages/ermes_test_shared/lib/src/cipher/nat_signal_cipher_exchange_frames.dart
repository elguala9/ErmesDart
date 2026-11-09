// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

part of 'nat_signal_cipher_exchange.dart';

/// Handler installation, frame dispatch and cipher assertion of
/// [NatSignalCipherExchange].
extension _NatSignalCipherFrames on NatSignalCipherExchange {
  /// The signal-derived shared secret must be registered by the production
  /// opener; without it there is nothing to prove and the scenario fails loud.
  void _assertSignalCipherActive() {
    final handler = ErmesPeerCipherHandler();
    final cipher =
        handler.get(peerCipherKey(peer, ErmesConnectionContext.ipv4)) ??
            handler.get(peerCipherKey(peer, ErmesConnectionContext.ipv6));
    if (cipher == null || !cipher.hasEncryptCipher) {
      throw StateError(
        'No signal-derived encrypt cipher registered for $peer: the '
        'shared-secret path did not run',
      );
    }
    print('[$tag] ${NatTestProtocol.cipherReadyMarker} signal cipher active.');
  }

  /// Registers the message handler that decodes and dispatches frames from
  /// the peer.
  Future<void> _installHandler() async {
    await orc.onMessage((data, from) {
      if (from != peer) {
        return;
      }
      try {
        _onExchange(MessageEnvelope.decode(data));
      } on Object catch (e) {
        print('[$tag] WARN: ignored undecodable frame (${data.length}B): $e');
      }
    });
  }

  /// Handles an incoming frame: tracks ready, ACKs, received data (auto-ACKing
  /// it) and the end-of-tests marker.
  void _onExchange(MessageEnvelope env) {
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

  /// Sends the fixed burst of encrypted `testData` messages to the peer.
  Future<void> _sendBurst() async {
    for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
      final env = MessageEnvelope(
        type: DockerMsgType.testData,
        testName: 'sig_$seq',
        seq: seq,
        payload: Uint8List.fromList([seq, seq + 1, 0xDE, 0xAD]),
      );
      await send(env);
      print('[$tag] >> SENT (signal-encrypted) ${env.describe()} '
          'to=${shortId(peer)}');
    }
  }

  /// Starts a timer that resends `ready` until the first data frame arrives.
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

  /// Throws if any expected seq in `[0, messageCount)` is missing from [got].
  void _verify(Set<int> got, String what) {
    for (var seq = 0; seq < NatTestProtocol.messageCount; seq++) {
      if (!got.contains(seq)) {
        throw StateError('Missing $what seq=$seq; got: $got');
      }
    }
  }
}
