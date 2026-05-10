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

class _MemSig extends INostrSignaling {
  _MemSig(this._accountId, this._store);
  final String _accountId;
  final Map<String, List<int>> _store;

  @override bool isConnected() => true;
  @override Future<void> connect() async {}
  @override Future<void> disconnect() async {}
  @override void destroy() {}
  @override Future<String> publish(List<int> data) async {
    _store[_accountId] = data;
    return 'eid';
  }
  @override Future<List<int>> retrieveLast(NostrUserId id) async =>
      _store[id.toString()] ?? [];
  @override Future<String> subscribe(
    NostrUserId id, covariant IEventCallback onEvent, {int? since}) async => 'sid';
  @override Future<void> unsubscribe(NostrUserId id) async {}
  @override void registerWith<T extends IValueForRegistry>() {}
  @override T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

class _FastSigHandler extends ErmesSignalingHandler {
  _FastSigHandler(IStunShspHandler handler, IShspSocket shspSocket,
      IErmesBookService<BookData> bookService, int port)
    : _localPort = port,
        super.create(handler, shspSocket, bookService, overridePort: port);

  final int _localPort;

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      ipv4Port: _localPort.toString(), ipv4: '127.0.0.1',
      ipv6Port: '', ipv6: '',
      publicKey: '', epochTimestampStartConversation: ts,
      epochTimestampExpireConversation: ts + 600,
    );
  }
}

OrcErmes _createOrc(
  IShspSocket shsp,
  IErmesBookService<BookData> book,
  IErmesSignalingHandler<ShspPeer> handler,
  IErmesSignalingServer server,
) {
  return OrcErmes(
    signalingServer: server, signalingHandler: handler,
    socket: shsp, bookService: book,
    enableEncryption: false, connectionTimeoutMs: 30000,
  );
}

Future<({RawDatagramSocket raw, ShspSocket shsp, IErmesBookService<BookData> book,
    IErmesSignalingHandler<ShspPeer> handler, IErmesSignalingServer server, OrcErmes orc})>
    _makePeer(String accountId, Map<String, List<int>> store) async {
  final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shsp = ShspSocket.fromRaw(raw);
  final book = ErmesBookService();
  book.setAccount(AccountInfo<BookData>(
    account: accountId,
    peerInfo: ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'), port: raw.port, id: accountId,
    ),
  ));
  final stun = StunShspHandlerSingleton.instance;
  if (!stun.isInitialized) await stun.initialize();
  final handler = _FastSigHandler(stun, shsp, book, raw.port);
  final server = ErmesSignalingServer(
    nostrSignaling: _MemSig(accountId, store), accountId: accountId,
  );
  final orc = _createOrc(shsp, book, handler, server);
  return (raw: raw, shsp: shsp, book: book, handler: handler,
      server: server, orc: orc);
}

void runDisconnectReconnectTests() {
  group('Multi-Peer Disconnect/Reconnect', () {
    late Map<String, List<int>> store;

    setUpAll(() { initialPointErmesStorage(); });
    setUp(() { store = {}; });

    const aId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const bId = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    const cId = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
    const centerId = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
    const p1Id = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
    const p2Id = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    const p3Id = '1111111111111111111111111111111111111111111111111111111111111111';

    test('2 peers: multiple open-close-reconnect cycles (3x)', () async {
      final a = await _makePeer(aId, store);
      final b = await _makePeer(bId, store);
      try {
        for (var cycle = 0; cycle < 3; cycle++) {
          await Future.wait([
            a.orc.openConnection(bId),
            b.orc.openConnection(aId),
          ]);
          var conns = await a.orc.getConnections();
          if (cycle == 0) {
            expect(conns, contains(bId));
          }
          await a.orc.closeConnection(bId);
          conns = await a.orc.getConnections();
          expect(conns, isEmpty);
        }
      } finally {
        await a.orc.destroy(); await b.orc.destroy();
        a.raw.close(); b.raw.close();
      }
    });

    test('3 peers: connect and exchange messages in chain A→B→C', () async {
      final a = await _makePeer(aId, store);
      final b = await _makePeer(bId, store);
      final c = await _makePeer(cId, store);
      try {
        await Future.wait([
          a.orc.openConnection(bId),
          b.orc.openConnection(aId),
          b.orc.openConnection(cId),
          c.orc.openConnection(bId),
        ]);
        await Future.delayed(const Duration(seconds: 2));

        var receivedByB = Uint8List(0);
        var receivedByC = Uint8List(0);
        await b.orc.onMessage((data, _) { receivedByB = data; });
        await c.orc.onMessage((data, _) { receivedByC = data; });

        final msg = Uint8List.fromList([1, 2, 3]);
        await a.orc.send(msg, bId);
        var waited = 0;
        while (receivedByB.isEmpty && waited < 30) {
          await Future.delayed(const Duration(milliseconds: 200));
          waited++;
        }
        expect(receivedByB, equals(msg));

        await b.orc.send(msg, cId);
        waited = 0;
        while (receivedByC.isEmpty && waited < 30) {
          await Future.delayed(const Duration(milliseconds: 200));
          waited++;
        }
        expect(receivedByC, equals(msg));
      } finally {
        await a.orc.destroy(); await b.orc.destroy(); await c.orc.destroy();
        a.raw.close(); b.raw.close(); c.raw.close();
      }
    });

    test('star topology: center connects 3 peers, disconnect 2, reconnect',
        () async {
      final center = await _makePeer(centerId, store);
      final p1 = await _makePeer(p1Id, store);
      final p2 = await _makePeer(p2Id, store);
      final p3 = await _makePeer(p3Id, store);
      try {
        await Future.wait([
          center.orc.openConnection(p1Id),
          p1.orc.openConnection(centerId),
          center.orc.openConnection(p2Id),
          p2.orc.openConnection(centerId),
          center.orc.openConnection(p3Id),
          p3.orc.openConnection(centerId),
        ]);
        await Future.delayed(const Duration(seconds: 2));

        var centerConns = await center.orc.getConnections();
        expect(centerConns, hasLength(3));

        await center.orc.closeConnection(p1Id);
        centerConns = await center.orc.getConnections();
        expect(centerConns, hasLength(2));

        await center.orc.closeConnection(p2Id);
        centerConns = await center.orc.getConnections();
        expect(centerConns, hasLength(1));

        await Future.wait([
          center.orc.openConnection(p1Id),
          p1.orc.openConnection(centerId),
          center.orc.openConnection(p2Id),
          p2.orc.openConnection(centerId),
        ]);
        await Future.delayed(const Duration(seconds: 2));
        centerConns = await center.orc.getConnections();
        expect(centerConns, hasLength(3));
      } finally {
        await center.orc.destroy(); await p1.orc.destroy();
        await p2.orc.destroy(); await p3.orc.destroy();
        center.raw.close(); p1.raw.close(); p2.raw.close(); p3.raw.close();
      }
    });
  });
}
