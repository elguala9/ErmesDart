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

/// In-memory Nostr signaling that shares signal data between
/// multiple instances via a common [Map].
class _SharedMemoryNostrSignaling extends INostrSignaling {
  final String _accountId;
  final Map<String, List<int>> _store;

  _SharedMemoryNostrSignaling(this._accountId, this._store);

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
    return 'fake-event-id';
  }

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async =>
      _store[id.toString()] ?? [];

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async =>
      'fake-sub-id';

  @override
  Future<void> unsubscribe(NostrUserId id) async {}

  @override
  void registerWith<T extends IValueForRegistry>() {}

  @override
  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}

/// Signaling handler that overrides [createSignal] to return
/// a signal with the local IP and port without doing STUN discovery.
/// This avoids the ~30s delay from STUN timeouts in test environments.
class _FastSignalingHandler extends ErmesSignalingHandler {
  _FastSignalingHandler(
    IStunShspHandler handler,
    IShspSocket shspSocket,
    IErmesBookService<BookData> bookService, {
    required int localPort,
  }) : _localPort = localPort,
        super.create(handler, shspSocket, bookService, overridePort: localPort);

  final int _localPort;

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) async {
    final nowEpoch =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      ipv4Port: _localPort.toString(),
      ipv4: '127.0.0.1',
      ipv6Port: '',
      ipv6: '',
      publicKey: '',
      epochTimestampStartConversation: nowEpoch,
      epochTimestampExpireConversation: nowEpoch + 600,
    );
  }
}

void main() {
  testOrcErmesFullFlow();
}

void testOrcErmesFullFlow() {
  group('OrcErmes full flow with in-memory signaling', () {
    late OrcErmes orcA;
    late OrcErmes orcB;
    late ShspSocket shspA;
    late ShspSocket shspB;
    late RawDatagramSocket rawA;
    late RawDatagramSocket rawB;

    final peerAId =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final peerBId =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    setUpAll(() async {
      initialPointErmesStorage();

      rawA = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      rawB = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

      shspA = ShspSocket.fromRaw(rawA);
      shspB = ShspSocket.fromRaw(rawB);

      final bookA = ErmesBookService();
      final bookB = ErmesBookService();
      bookA.setAccount(AccountInfo<BookData>(
        account: peerAId,
        peerInfo: ErmesPeerInfo(
          address: InternetAddress('127.0.0.1'),
          port: rawA.port,
          id: peerAId,
        ),
      ));
      bookB.setAccount(AccountInfo<BookData>(
        account: peerBId,
        peerInfo: ErmesPeerInfo(
          address: InternetAddress('127.0.0.1'),
          port: rawB.port,
          id: peerBId,
        ),
      ));

      final stunHandler = StunShspHandlerSingleton.instance;
      if (!stunHandler.isInitialized) {
        await stunHandler.initialize();
      }

      final handlerA = _FastSignalingHandler(
        stunHandler, shspA, bookA,
        localPort: rawA.port,
      );
      final handlerB = _FastSignalingHandler(
        stunHandler, shspB, bookB,
        localPort: rawB.port,
      );

      final sharedStore = <String, List<int>>{};
      final sigA = _SharedMemoryNostrSignaling(peerAId, sharedStore);
      final sigB = _SharedMemoryNostrSignaling(peerBId, sharedStore);

      final serverA = ErmesSignalingServer(
        nostrSignaling: sigA,
        accountId: peerAId,
      );
      final serverB = ErmesSignalingServer(
        nostrSignaling: sigB,
        accountId: peerBId,
      );

      orcA = OrcErmes(
        signalingServer: serverA,
        signalingHandler: handlerA,
        socket: shspA,
        bookService: bookA,
        enableEncryption: false,
        connectionTimeoutMs: 30000,
      );
      orcB = OrcErmes(
        signalingServer: serverB,
        signalingHandler: handlerB,
        socket: shspB,
        bookService: bookB,
        enableEncryption: false,
        connectionTimeoutMs: 30000,
      );
    });

    tearDownAll(() async {
      await orcA.destroy();
      await orcB.destroy();
      rawA.close();
      rawB.close();
    });

    test('two peers connect and exchange messages via the full OrcErmes flow',
        () async {
      var receivedByA = Uint8List(0);
      var receivedByB = Uint8List(0);
      var receiveCountA = 0;
      var receiveCountB = 0;

      await orcA.onMessage((data, peerId) {
        receivedByA = data;
        receiveCountA++;
      });
      await orcB.onMessage((data, peerId) {
        receivedByB = data;
        receiveCountB++;
      });

      // Connect both peers in parallel so handshake messages cross
      await Future.wait([
        orcA.openConnection(peerBId),
        orcB.openConnection(peerAId),
      ]);

      // Allow handshake completion and I/O event processing
      await Future.delayed(const Duration(seconds: 2));

      final connectionsA = await orcA.getConnections();
      expect(connectionsA, isNotEmpty);
      expect(connectionsA, contains(peerBId));

      final dataAB = Uint8List.fromList([10, 20, 30]);
      await orcA.send(dataAB, peerBId);

      var waited = 0;
      while (receiveCountB == 0 && waited < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        waited++;
      }
      expect(receiveCountB, greaterThan(0));
      expect(receivedByB, equals(dataAB));

      final dataBA = Uint8List.fromList([40, 50, 60]);
      await orcB.send(dataBA, peerAId);

      waited = 0;
      while (receiveCountA == 0 && waited < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        waited++;
      }
      expect(receiveCountA, greaterThan(0));
      expect(receivedByA, equals(dataBA));
    });

    test('peer lifecycle: open, close, reconnect', () async {
      await Future.wait([
        orcA.openConnection(peerBId),
        orcB.openConnection(peerAId),
      ]);

      await orcA.closeConnection(peerBId);

      final connectionsA = await orcA.getConnections();
      expect(connectionsA, isEmpty);

      await Future.wait([
        orcA.openConnection(peerBId),
        orcB.openConnection(peerAId),
      ]);

      final connectionsAfter = await orcA.getConnections();
      expect(connectionsAfter, isNotEmpty);
    });
  });
}
