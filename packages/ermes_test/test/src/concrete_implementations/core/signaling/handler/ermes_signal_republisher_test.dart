import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import '../../../../helpers/in_memory_signaling.dart';

/// Real handler whose advertised port can be moved, simulating NAT rebinding.
class _MovableHandler extends LocalhostSignalingHandler {
  _MovableHandler(
    IStunShspHandler stun,
    IShspSocket socket,
    IErmesBookService<BookData> book,
    this.port,
  ) : super(stun, socket, book, port);

  int port;

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
    String? localIdSignaling,
  ]) async {
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return SignalErmes(
      idSignaling: localIdSignaling ?? 'test-peer',
      ipv4Port: port.toString(),
      ipv4: '127.0.0.1',
      ipv6Port: '',
      ipv6: '',
      publicKey: '',
      epochTimestampStartConversation: ts,
      epochTimestampExpireConversation: ts + 600,
    );
  }
}

void main() {
  testErmesSignalRepublisher();
}

void testErmesSignalRepublisher() {
  group('ErmesSignalRepublisher', () {
    final id = '1'.padLeft(64, '0');
    late Map<String, List<int>> store;
    late _MovableHandler handler;
    late IErmesSignalingServer server;

    IErmesSignalRepublisher build(Duration minInterval) =>
        ErmesSignalRepublisherFactory.create(
          ErmesSignalRepublisherInput(
            server: server,
            handler: handler,
            minInterval: minInterval,
          ),
        );

    setUp(() async {
      store = {};
      final peer = await createInMemoryPeer(
        accountId: id,
        store: store,
        subscriptions: {},
      );
      handler = _MovableHandler(
        await _stun(),
        peer.shsp,
        peer.book,
        peer.raw.port,
      );
      server = peer.server;
    });

    test('publishes once, then nothing while the mapping is stable', () async {
      final r = build(Duration.zero);
      expect(await r.checkNow(), isTrue);
      expect(await r.checkNow(), isFalse);
      expect(await r.checkNow(), isFalse);
      final signal = await server.getSignal(id, forceRefresh: true);
      expect(signal.ipv4Port, handler.port.toString());
    });

    test('a mapping change triggers exactly one republish', () async {
      final r = build(Duration.zero);
      await r.checkNow();
      handler.port = 40001;
      expect(await r.checkNow(), isTrue);
      expect(await r.checkNow(), isFalse);
      final signal = await server.getSignal(id, forceRefresh: true);
      expect(signal.ipv4Port, '40001');
    });

    test('flapping within the minimum interval is deferred', () async {
      final r = build(const Duration(minutes: 5));
      await r.checkNow();
      handler.port = 40002;
      expect(await r.checkNow(), isFalse);
      handler.port = 40003;
      expect(await r.checkNow(), isFalse);
    });
  });
}

Future<IStunShspHandler> _stun() => StunShspHandler.createDefault(ipv6: false);
