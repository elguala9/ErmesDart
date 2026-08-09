import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// In-memory Nostr signaling for multi-peer tests.
///
/// Stores published signals per account in a shared map and delivers
/// them via [retrieveLast] on demand. Also notifies subscribers on
/// publish, acting as a local relay.
class InMemoryNostrSignaling extends INostrSignaling {
  InMemoryNostrSignaling(this._accountId, this._store, this._subscriptions);

  final String _accountId;
  final Map<String, List<int>> _store;
  final Map<String, List<InMemorySubscription>> _subscriptions;

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
    _store[_accountId] = data;
    for (final entry in _subscriptions.entries) {
      if (entry.key == _accountId) {
        for (final sub in entry.value) {
          sub.onEvent('', data);
        }
      }
    }
    return 'mem-event-id';
  }

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async =>
      List<int>.from(_store[id] ?? []);

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async {
    _subscriptions.putIfAbsent(id, () => []);
    _subscriptions[id]!.add(InMemorySubscription(id, onEvent));
    return 'mem-sub-id';
  }

  @override
  Future<void> unsubscribe(NostrUserId id) async {
    _subscriptions.remove(id);
  }

}

class InMemorySubscription {
  InMemorySubscription(this.peerId, this.onEvent);
  final String peerId;
  final IEventCallback onEvent;
}

/// Simplified signaling handler that returns localhost signals.
///
/// Avoids STUN discovery by returning a pre-built signal with
/// [loopbackIp] and [port], making it suitable for in-memory tests.
class LocalhostSignalingHandler extends ErmesSignalingHandler {
  LocalhostSignalingHandler(
    super.handler,
    super.shspSocket,
    super.bookService,
    this._port, {
    String loopbackIp = '127.0.0.1',
  })  : _loopbackIp = loopbackIp,
        super.create(overridePort: _port);

  final int _port;
  final String _loopbackIp;

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      ipv4Port: _port.toString(),
      ipv4: _loopbackIp,
      ipv6Port: '',
      ipv6: '',
      publicKey: localPublicKey ?? '',
      epochTimestampStartConversation: ts,
      epochTimestampExpireConversation: ts + 600,
    );
  }
}

/// Creates a complete in-memory peer setup for testing.
///
/// Returns raw socket, SHSP socket, book service, localhost signaling
/// handler, in-memory Nostr signaling server, and OrcErmes instance all
/// wired together.
Future<({
  RawDatagramSocket raw,
  ShspSocket shsp,
  IErmesBookService<BookData> book,
  IErmesSignalingHandler<ShspPeer> handler,
  IErmesSignalingServer server,
  OrcErmes orc,
})>
    createInMemoryPeer({
  required String accountId,
  required Map<String, List<int>> store,
  required Map<String, List<InMemorySubscription>> subscriptions,
  bool enableEncryption = false,
}) async {
  final raw = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shsp = ShspSocket.fromRaw(raw);
  final book = ErmesBookService()
    ..setAccount(AccountInfo<BookData>(
      account: accountId,
      peerInfo: ErmesPeerInfo(
        address: InternetAddress('127.0.0.1'),
        port: raw.port,
        id: accountId,
      ),
    ));
  // stun_shsp 0.4.0 deleted StunShspHandlerSingleton; build a handler on its
  // own socket, exactly as the singleton held one.
  final stun = await StunShspHandler.createDefault(ipv6: false);
  final handler = LocalhostSignalingHandler(stun, shsp, book, raw.port);
  final server = ErmesSignalingServer(
    nostrSignaling: InMemoryNostrSignaling(accountId, store, subscriptions),
    accountId: accountId,
  );
  final orc = OrcErmes(
    signalingServer: server,
    signalingHandler: handler,
    socket: shsp,
    bookService: book,
    enableEncryption: enableEncryption,
  );
  return (raw: raw, shsp: shsp, book: book, handler: handler,
      server: server, orc: orc);
}
