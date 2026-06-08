import 'dart:async';
import 'dart:io';

import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_peer.dart';
import 'exceptions.dart';
import 'factories/ermes_peer_factory.dart';

/// Encapsulates the multi-step handshake performed by
/// `OrcErmes.openConnection`: signal publish, peer-signal polling,
/// book entry creation and `ErmesPeer` initialization. Pulled out of
/// `OrcErmes` to keep that class focused on the orchestration surface.
class OrcConnectionOpener {
  OrcConnectionOpener({
    required this.signalingServer,
    required this.signalingHandler,
    required this.socket,
    required this.bookService,
    required this.enableEncryption,
    required this.connectionTimeoutMs,
  });

  final IErmesSignalingServer signalingServer;
  final IErmesSignalingHandler<ShspPeer> signalingHandler;
  final IShspSocket socket;
  final IErmesBookService<BookData> bookService;
  final bool enableEncryption;
  final int connectionTimeoutMs;

  static const int _maxSignalAttempts = 60;

  Future<ErmesPeer> open(
    IdPeer peer,
    void Function(TypeOfData data, IdPeer from) onData,
    Future<void> Function(IdPeer peer) onPeerDisconnect,
  ) async {
    final ourSignal = await signalingHandler.createSignal(peer);
    await signalingServer.setSignal(ourSignal, peer);

    final peerSignal = await _waitForPeerSignal(peer);
    final peerInfo = peerInfoFromSignal(peerSignal, peer);

    bookService.setAccount(
      AccountInfo<BookData>(account: peer, peerInfo: peerInfo),
    );

    final ermesPeer = ErmesPeerFactory.create(
      ErmesPeerConfig(
        remotePeerId: peer,
        socket: socket,
        signalingHandler: signalingHandler,
        ermesBookService: bookService,
        idHandler: IdHandlerServiceFactory.createDefault(),
        timeoutMs: connectionTimeoutMs,
        enableEncryption: enableEncryption,
      ),
    )..addOnMessageListener((data) => onData(data, peer));

    await ermesPeer.initialize(initiateKeyExchange: enableEncryption);
    ermesPeer.addOnDisconnectListener(
      () => unawaited(onPeerDisconnect(peer)),
    );

    return ermesPeer;
  }

  Future<ISignalErmes> _waitForPeerSignal(IdPeer peer) async {
    for (var attempt = 0; attempt < _maxSignalAttempts; attempt++) {
      try {
        final s = await signalingServer.getSignal(peer);
        if (!s.isExpired()) {
          return s;
        }
      } on Exception {
        // peer hasn't published yet — keep polling
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw CoreException(
      'Timeout waiting for peer signal after $_maxSignalAttempts attempts',
    );
  }
}

/// Extracts an [ErmesPeerInfo] from a remote [ISignalErmes].
///
/// Prefers IPv6 when present and non-empty, otherwise falls back to
/// IPv4. Throws [CoreException] when neither produces a valid host/port.
ErmesPeerInfo peerInfoFromSignal(ISignalErmes signal, IdAccountType peerId) {
  String? host;
  int? port;

  if (signal.ipv6.isNotEmpty && signal.ipv6 != '::') {
    host = signal.ipv6;
    port = int.tryParse(signal.ipv6Port);
  }

  if ((host == null || host.isEmpty) && signal.ipv4.isNotEmpty) {
    host = signal.ipv4;
    port = int.tryParse(signal.ipv4Port);
  }

  if (host == null || host.isEmpty || port == null || port <= 0) {
    throw CoreException(
      'Invalid peer signal for $peerId: no valid IP address. '
      'IPv6: ${signal.ipv6}:${signal.ipv6Port}, '
      'IPv4: ${signal.ipv4}:${signal.ipv4Port}',
    );
  }

  return ErmesPeerInfo(
    address: InternetAddress(host),
    port: port,
    id: peerId,
  );
}
