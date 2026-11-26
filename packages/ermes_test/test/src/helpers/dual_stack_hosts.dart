/// Loopback dual-stack OrcErmes hosts shared by the dual-stack tests.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Peer A account id.
final String dualIdA = 'a' * 64;

/// Peer B account id.
final String dualIdB = 'b' * 64;

class DualMemoryNostr extends INostrSignaling {
  DualMemoryNostr(this._account, this._store);
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
class DualSignalHandler extends ErmesSignalingHandler {
  DualSignalHandler(
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

class DualHost {
  DualHost(this.id, this.orc, this.raws);
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

Future<DualHost> dualHost(
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
  final handler = DualSignalHandler(
    stun,
    (s4 ?? s6)!,
    book,
    port4: v4 ? raws.first.port : null,
    port6: v6 ? raws.last.port : null,
  );
  final server = ErmesSignalingServer(
    nostrSignaling: DualMemoryNostr(id, store),
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
  final host = DualHost(id, orc, raws);
  await orc.onMessage((data, from) => host.received.add(data));
  return host;
}

Future<void> dualConnect(DualHost a, DualHost b) =>
    Future.wait([a.orc.openConnection(b.id), b.orc.openConnection(a.id)]);

Future<void> dualExpectDelivered(DualHost to, Uint8List data) async {
  for (var i = 0; i < 40; i++) {
    if (to.received.any((m) => m.length == data.length && m[0] == data[0])) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('message ${data[0]} was not delivered to ${to.id}');
}

Set<ErmesConnectionContext> dualFamilies(DualHost h, String peer) => {
  for (final k in h.orc.getConnectionKeys())
    if (k.peer == peer) k.context,
};
