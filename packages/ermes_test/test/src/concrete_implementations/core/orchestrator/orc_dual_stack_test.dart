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

import '../../../helpers/test_helpers.dart';

const _idA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _idB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

class _MemoryNostr extends INostrSignaling {
  _MemoryNostr(this._account, this._store);
  final String _account;
  final Map<String, List<int>> _store;

  @override
  bool isConnected() => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> destroy() async {}
  @override
  Future<String> publish(List<int> data) async {
    _store[_account] = data;
    return 'id';
  }

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => _store[id] ?? [];
  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async => 'sub';
  @override
  Future<void> unsubscribe(NostrUserId id) async {}
}

/// Advertises a loopback endpoint for each family this host runs.
class _SignalHandler extends ErmesSignalingHandler {
  _SignalHandler(
    super.handler,
    super.shspSocket,
    super.bookService, {
    required this.port4,
    required this.port6,
  }) : super.create();

  final int? port4;
  final int? port6;

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
    String? localIdSignaling,
  ]) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      idSignaling: localIdSignaling ?? 'p',
      ipv4: port4 == null ? '' : '127.0.0.1',
      ipv4Port: port4?.toString() ?? '',
      ipv6: port6 == null ? '' : '::1',
      ipv6Port: port6?.toString() ?? '',
      publicKey: localPublicKey ?? '',
      epochTimestampStartConversation: now,
      epochTimestampExpireConversation: now + 600,
    );
  }
}

class _Host {
  _Host(this.id, this.orc, this.raws);
  final String id;
  final OrcErmes orc;
  final List<RawDatagramSocket> raws;
  final List<Uint8List> received = [];

  Future<void> close() async {
    await orc.destroy(force: true);
    for (final raw in raws) {
      raw.close();
    }
  }
}

Future<_Host> _host(
  String id,
  Map<String, List<int>> store, {
  required bool v4,
  required bool v6,
}) async {
  final raws = <RawDatagramSocket>[];
  ShspSocket? s4;
  ShspSocket? s6;
  if (v4) {
    final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    raws.add(raw);
    s4 = ShspSocket.fromRaw(raw);
  }
  if (v6) {
    final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv6, 0);
    raws.add(raw);
    s6 = ShspSocket.fromRaw(raw);
  }
  final book = ErmesBookService();
  final stun = await createTestStunShspHandler();
  final handler = _SignalHandler(
    stun,
    (s4 ?? s6)!,
    book,
    port4: v4 ? raws.first.port : null,
    port6: v6 ? raws.last.port : null,
  );
  final server = ErmesSignalingServer(
    nostrSignaling: _MemoryNostr(id, store),
    accountId: id,
  );
  final orc = OrcErmes(
    signalingServer: server,
    signalingHandler: handler,
    socket: s4,
    socketIpv6: s6,
    bookService: book,
    enableEncryption: false,
  );
  final host = _Host(id, orc, raws);
  await orc.onMessage((data, from) => host.received.add(data));
  return host;
}

Future<void> _connect(_Host a, _Host b) => Future.wait([
  a.orc.openConnection(b.id),
  b.orc.openConnection(a.id),
]);

Future<void> _expectDelivered(_Host to, Uint8List data) async {
  for (var i = 0; i < 40; i++) {
    if (to.received.any((m) => m.length == data.length && m[0] == data[0])) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('message ${data[0]} was not delivered to ${to.id}');
}

Set<ErmesConnectionContext> _families(_Host h, String peer) => {
  for (final k in h.orc.getConnectionKeys())
    if (k.peer == peer) k.context,
};

void main() {
  testOrcDualStack();
}

/// RFC sections 2, 5 and 6.2: one independent Connection per address family.
void testOrcDualStack() {
  group('OrcErmes dual-stack Connections', () {
    setUpAll(registerErmesStorageHandlers);

    test('dual-stack hosts open one Connection per family', () async {
      final store = <String, List<int>>{};
      final a = await _host(_idA, store, v4: true, v6: true);
      final b = await _host(_idB, store, v4: true, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await _connect(a, b);

      expect(_families(a, _idB), {
        ErmesConnectionContext.ipv4,
        ErmesConnectionContext.ipv6,
      });
      expect(await a.orc.getConnections(), [_idB]);
    });

    test('IPv4-only peer yields a single IPv4 Connection', () async {
      final store = <String, List<int>>{};
      final a = await _host(_idA, store, v4: true, v6: true);
      final b = await _host(_idB, store, v4: true, v6: false);
      addTearDown(a.close);
      addTearDown(b.close);

      await _connect(a, b);

      expect(_families(a, _idB), {ErmesConnectionContext.ipv4});
      expect(_families(b, _idA), {ErmesConnectionContext.ipv4});
    });

    test('IPv6-only hosts yield a single IPv6 Connection', () async {
      final store = <String, List<int>>{};
      final a = await _host(_idA, store, v4: false, v6: true);
      final b = await _host(_idB, store, v4: false, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await _connect(a, b);
      final data = Uint8List.fromList([7, 7, 7]);
      await a.orc.send(data, _idB);

      expect(_families(a, _idB), {ErmesConnectionContext.ipv6});
      await _expectDelivered(b, data);
    });

    test('families carry data independently and one can be closed', () async {
      final store = <String, List<int>>{};
      final a = await _host(_idA, store, v4: true, v6: true);
      final b = await _host(_idB, store, v4: true, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);
      await _connect(a, b);

      final over4 = Uint8List.fromList([4, 1, 1]);
      final over6 = Uint8List.fromList([6, 2, 2]);
      await a.orc.sendOverFamily(
        over4,
        _idB,
        family: ErmesConnectionContext.ipv4,
      );
      await a.orc.sendOverFamily(
        over6,
        _idB,
        family: ErmesConnectionContext.ipv6,
      );
      await _expectDelivered(b, over4);
      await _expectDelivered(b, over6);

      await a.orc.closeFamily(_idB, ErmesConnectionContext.ipv6);
      expect(_families(a, _idB), {ErmesConnectionContext.ipv4});

      final after = Uint8List.fromList([9, 3, 3]);
      await a.orc.sendOverFamily(
        after,
        _idB,
        family: ErmesConnectionContext.ipv4,
      );
      await _expectDelivered(b, after);
      await expectLater(
        a.orc.sendOverFamily(
          after,
          _idB,
          family: ErmesConnectionContext.ipv6,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('hosts with no common family fail to open', () async {
      final store = <String, List<int>>{};
      final a = await _host(_idA, store, v4: true, v6: false);
      final b = await _host(_idB, store, v4: false, v6: true);
      addTearDown(a.close);
      addTearDown(b.close);

      await expectLater(
        Future.wait([a.orc.openConnection(_idB), b.orc.openConnection(_idA)]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
