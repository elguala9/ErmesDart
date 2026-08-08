import 'dart:async';
import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

/// Pool of public Nostr relays raced on each publish. `NostrSignalingImpl`
/// resolves as soon as any one relay accepts the event, so a slow/unreachable
/// relay in the pool no longer fails the whole publish — only if ALL of them
/// time out does "All relays failed to publish" surface. `relay.damus.io`
/// alone rejects anonymous writes; same pool as NOSTR_RELAYS in the NAT CI
/// workflows (see .github/workflows/nat-test.yml).
const defaultTestRelayUrls = <String>[
  'wss://nos.lol',
  'wss://relay.damus.io',
  'wss://nostr-pub.wellorder.net',
  'wss://relay.primal.net',
];

/// Complete signaling setup for a peer in tests.
///
/// Creates real Nostr relay connections and properly wired SHSP/STUN
/// components — no empty stubs.
class TestSignalingSetup {
  TestSignalingSetup({
    required this.keyPair,
    required this.nostrSignaling,
    required this.signalingServer,
    required this.signalingHandler,
    required this.rawSocket,
    required this.shspSocket,
    required this.bookService,
  });

  final NostrKeyPair keyPair;
  final INostrSignaling nostrSignaling;
  final ErmesSignalingServer signalingServer;
  final ErmesSignalingHandler signalingHandler;
  final RawDatagramSocket rawSocket;
  final ShspSocket shspSocket;
  final IErmesBookService<BookData> bookService;

  IdAccountType get accountId => keyPair.publicKey;

  Future<void> dispose() async {
    await signalingServer.destroy();
    await signalingHandler.destroy();
    rawSocket.close();
  }
}

/// Creates a complete test signaling setup with real Nostr relay connection.
///
/// Each call generates unique Nostr keys and opens a WebSocket connection
/// to the specified relay. The STUN handler is initialized once (shared
/// singleton) across all calls.
///
/// [relayUrls] Nostr relay URLs to race a publish across (default: a small
/// pool of public relays). `publish()` only needs one relay to succeed, so
/// listing several here is what makes a single flaky/slow relay non-fatal.
/// [stunServer] Optional custom STUN server for NAT traversal
Future<TestSignalingSetup> createTestSignalingSetup({
  List<String> relayUrls = defaultTestRelayUrls,
  String? stunServer,
  int stunPort = 19302,
  int? overridePort,
}) async {
  final keyPair = NostrKeys.generate();
  final accountId = keyPair.publicKey;

  final rawSocket =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shspSocket = ShspSocket.fromRaw(rawSocket);

  final bookService = ErmesBookService()
    ..setAccount(AccountInfo<BookData>(
      account: accountId,
      peerInfo: ErmesPeerInfo(
        address: InternetAddress('127.0.0.1'),
        port: rawSocket.port,
        id: accountId,
      ),
    ));

  // stun_shsp 0.4.0 deleted StunShspHandlerSingleton; build a handler on its
  // own socket, exactly as the singleton held one.
  final stunHandler = await StunShspHandler.createDefault(ipv6: false);
  if (stunServer != null) {
    stunHandler.setStunServer(stunServer, stunPort);
  }

  final nostrSignaling = NostrSignalingFactory.create(
    keyPair: keyPair,
    relayUrls: relayUrls,
  );
  await nostrSignaling.connect();

  final signalingServer = ErmesSignalingServer(
    nostrSignaling: nostrSignaling,
    accountId: accountId,
  );

  final signalingHandler = ErmesSignalingHandler.create(
    stunHandler,
    shspSocket,
    bookService,
    overridePort: overridePort,
  );

  return TestSignalingSetup(
    keyPair: keyPair,
    nostrSignaling: nostrSignaling,
    signalingServer: signalingServer,
    signalingHandler: signalingHandler,
    rawSocket: rawSocket,
    shspSocket: shspSocket,
    bookService: bookService,
  );
}

/// Creates multiple independent test signaling setups for multi-peer tests.
///
/// Each peer gets unique Nostr keys and its own relay connection.
Future<List<TestSignalingSetup>> createTestSignalingSetups({
  required int count,
  List<String> relayUrls = defaultTestRelayUrls,
}) async {
  final setups = <TestSignalingSetup>[];
  for (var i = 0; i < count; i++) {
    setups.add(await createTestSignalingSetup(relayUrls: relayUrls));
  }
  return setups;
}
