import 'dart:async';
import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';

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
/// [relayUrl] Nostr relay URL (default: wss://relay.damus.io)
/// [stunServer] Optional custom STUN server for NAT traversal
Future<TestSignalingSetup> createTestSignalingSetup({
  String relayUrl = 'wss://relay.damus.io',
  String? stunServer,
  int stunPort = 19302,
  int? overridePort,
}) async {
  final keyPair = NostrKeys.generate();
  final accountId = keyPair.publicKey;

  final rawSocket =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shspSocket = ShspSocket.fromRaw(rawSocket);

  final bookService = ErmesBookService();
  bookService.setAccount(AccountInfo<BookData>(
    account: accountId,
    peerInfo: ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: rawSocket.port,
      id: accountId,
    ),
  ));

  final stunHandler = StunShspHandlerSingleton.instance;
  if (!stunHandler.isInitialized) {
    await stunHandler.initialize();
  }
  if (stunServer != null) {
    stunHandler.setStunServer(stunServer, stunPort);
  }

  final nostrSignaling = NostrSignalingFactory.create(
    keyPair: keyPair,
    relayUrl: relayUrl,
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
  String relayUrl = 'wss://relay.damus.io',
}) async {
  final setups = <TestSignalingSetup>[];
  for (var i = 0; i < count; i++) {
    setups.add(await createTestSignalingSetup(relayUrl: relayUrl));
  }
  return setups;
}
