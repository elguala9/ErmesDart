import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// In-memory Nostr signaling sharing signals via a common [Map].
class _MemSig extends INostrSignaling {
  _MemSig(this._accountId, this._store);
  final String _accountId;
  final Map<String, List<int>> _store;

  @override
  bool isConnected() => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  void destroy() {}
  @override
  Future<String> publish(List<int> data) async {
    _store[_accountId] = data;
    return 'eid';
  }

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => _store[id] ?? [];
  @override
  Future<String> subscribe(NostrUserId id, covariant IEventCallback onEvent,
          {int? since}) async =>
      'sid';
  @override
  Future<void> unsubscribe(NostrUserId id) async {}
  void registerWith<T extends IValueForRegistry>() {}
  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

/// Signaling handler that returns the local loopback port without STUN.
class _FastSigHandler extends ErmesSignalingHandler {
  _FastSigHandler(super.handler, super.shspSocket, super.bookService, int port)
      : _localPort = port,
        super.create(overridePort: port);

  final int _localPort;

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      ipv4Port: _localPort.toString(),
      ipv4: '127.0.0.1',
      ipv6Port: '',
      ipv6: '',
      publicKey: localPublicKey ?? '',
      epochTimestampStartConversation: ts,
      epochTimestampExpireConversation: ts + 600,
    );
  }
}

/// Serves [target]'s signal as a stale dead-port one on the first read, then
/// delegates to the real (fresher) signal — mimicking a relay still holding a
/// leftover signal from an earlier run while the peer publishes a fresh one.
class _StaleThenFreshServer extends ErmesSignalingServer {
  _StaleThenFreshServer({
    required super.nostrSignaling,
    required super.accountId,
    required this.target,
    required this.staleSignal,
  });

  final IdAccountType target;
  final SignalErmes staleSignal;
  int _reads = 0;

  @override
  Future<SignalErmes> getSignal(IdAccountType from,
      {bool forceRefresh = false}) async {
    if (from == target && _reads++ == 0) {
      return staleSignal;
    }
    return super.getSignal(from, forceRefresh: forceRefresh);
  }
}

void main() {
  testOrcErmesRedial();
  testOrcErmesSelfDial();
}

void testOrcErmesRedial() {
  group('OrcErmes re-dial on fresher signal', () {
    const peerAId =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const peerBId =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    test('first dial targets a dead port, then re-dials the live peer',
        () async {
      initialPointErmesStorage();

      final rawA =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rawB =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      // Reserve then release a port so the first dial aims at a dead one.
      final deadRaw =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = deadRaw.port;
      deadRaw.close();

      final shspA = ShspSocket.fromRaw(rawA);
      final shspB = ShspSocket.fromRaw(rawB);

      ErmesBookService makeBook(String id, int port) => ErmesBookService()
        ..setAccount(AccountInfo<BookData>(
          account: id,
          peerInfo: ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: port,
            id: id,
          ),
        ));
      final bookA = makeBook(peerAId, rawA.port);
      final bookB = makeBook(peerBId, rawB.port);

      final stun = StunShspHandlerSingleton.instance;
      if (!stun.isInitialized) {
        await stun.initialize();
      }
      final handlerA = _FastSigHandler(stun, shspA, bookA, rawA.port);
      final handlerB = _FastSigHandler(stun, shspB, bookB, rawB.port);

      final store = <String, List<int>>{};
      final staleTs =
          (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) - 100;
      final serverA = _StaleThenFreshServer(
        nostrSignaling: _MemSig(peerAId, store),
        accountId: peerAId,
        target: peerBId,
        staleSignal: SignalErmes(
          ipv4: '127.0.0.1',
          ipv4Port: deadPort.toString(),
          ipv6: '',
          ipv6Port: '',
          publicKey: '',
          epochTimestampStartConversation: staleTs,
          epochTimestampExpireConversation: staleTs + 600,
        ),
      );
      final serverB = ErmesSignalingServer(
        nostrSignaling: _MemSig(peerBId, store),
        accountId: peerBId,
      );

      final orcA = OrcErmes(
        signalingServer: serverA,
        signalingHandler: handlerA,
        socket: shspA,
        bookService: bookA,
        enableEncryption: false,
      );
      final orcB = OrcErmes(
        signalingServer: serverB,
        signalingHandler: handlerB,
        socket: shspB,
        bookService: bookB,
        enableEncryption: false,
      );

      try {
        var receivedByB = Uint8List(0);
        await orcB.onMessage((data, _) => receivedByB = data);

        await Future.wait([
          orcA.openConnection(peerBId),
          orcB.openConnection(peerAId),
        ]);

        // The dead-port dial never completes the handshake; only the re-dial
        // to the fresh signal does, so a delivered message proves the re-dial.
        final msg = Uint8List.fromList([7, 8, 9]);
        await orcA.send(msg, peerBId);

        var waited = 0;
        while (receivedByB.isEmpty && waited < 50) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          waited++;
        }
        expect(receivedByB, equals(msg),
            reason: 'message must arrive via the re-dialled live mapping');
      } finally {
        await orcA.destroy();
        await orcB.destroy();
        rawA.close();
        rawB.close();
      }
    });
  });
}

/// Regression test for the anti-self-dial guard in [OrcConnectionOpener]: when
/// the relay hands a peer back its OWN signal (no live counterpart has
/// published yet), the opener must NOT dial itself — which on loopback would
/// "connect" by hairpin and mask the absent peer — but skip it and connect to
/// the real peer once its fresh signal appears.
void testOrcErmesSelfDial() {
  group('OrcErmes anti-self-dial', () {
    const peerAId =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const peerBId =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    test('skips our own reflected signal and reaches the real peer', () async {
      initialPointErmesStorage();

      final rawA =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rawB =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final shspA = ShspSocket.fromRaw(rawA);
      final shspB = ShspSocket.fromRaw(rawB);

      ErmesBookService makeBook(String id, int port) => ErmesBookService()
        ..setAccount(AccountInfo<BookData>(
          account: id,
          peerInfo: ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: port,
            id: id,
          ),
        ));
      final bookA = makeBook(peerAId, rawA.port);
      final bookB = makeBook(peerBId, rawB.port);

      final stun = StunShspHandlerSingleton.instance;
      if (!stun.isInitialized) {
        await stun.initialize();
      }
      final handlerA = _FastSigHandler(stun, shspA, bookA, rawA.port);
      final handlerB = _FastSigHandler(stun, shspB, bookB, rawB.port);

      final store = <String, List<int>>{};
      final freshTs = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      // The relay hands peer A back ITS OWN endpoint (127.0.0.1:rawA.port) as
      // if it were peer B's — a fresh, non-expired copy of our own signal.
      final serverA = _StaleThenFreshServer(
        nostrSignaling: _MemSig(peerAId, store),
        accountId: peerAId,
        target: peerBId,
        staleSignal: SignalErmes(
          ipv4: '127.0.0.1',
          ipv4Port: rawA.port.toString(),
          ipv6: '',
          ipv6Port: '',
          publicKey: '',
          epochTimestampStartConversation: freshTs,
          epochTimestampExpireConversation: freshTs + 600,
        ),
      );
      final serverB = ErmesSignalingServer(
        nostrSignaling: _MemSig(peerBId, store),
        accountId: peerBId,
      );

      final orcA = OrcErmes(
        signalingServer: serverA,
        signalingHandler: handlerA,
        socket: shspA,
        bookService: bookA,
        enableEncryption: false,
      );
      final orcB = OrcErmes(
        signalingServer: serverB,
        signalingHandler: handlerB,
        socket: shspB,
        bookService: bookB,
        enableEncryption: false,
      );

      try {
        var receivedByB = Uint8List(0);
        await orcB.onMessage((data, _) => receivedByB = data);

        await Future.wait([
          orcA.openConnection(peerBId),
          orcB.openConnection(peerAId),
        ]);

        // Without the guard, A would connect to itself via loopback hairpin and
        // never reach B, so a delivered message proves the self signal was
        // skipped and the real peer dialled instead.
        final msg = Uint8List.fromList([1, 2, 3]);
        await orcA.send(msg, peerBId);

        var waited = 0;
        while (receivedByB.isEmpty && waited < 50) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          waited++;
        }
        expect(receivedByB, equals(msg),
            reason: 'A must skip its own reflected signal and reach real B');
      } finally {
        await orcA.destroy();
        await orcB.destroy();
        rawA.close();
        rawB.close();
      }
    });
  });
}
