
import 'dart:async';
import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Signaling stack setup with real Nostr relay connection.
class _SignalingStack {
  _SignalingStack({
    required this.keyPair,
    required this.service,
    required this.repository,
    required this.server,
    required this.handler,
    required this.rawSocket,
    required this.bookService,
  });

  final NostrKeyPair keyPair;
  final ErmesSignalingService service;
  final ErmesSignalingRepository repository;
  final ErmesSignalingServer server;
  final ErmesSignalingHandler handler;
  final RawDatagramSocket rawSocket;
  final IErmesBookService<BookData> bookService;

  Future<void> dispose() async {
    await service.destroy();
    await handler.destroy();
    rawSocket.close();
  }
}

Future<_SignalingStack> _createStack() async {
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

  final nostrSignaling = NostrSignalingFactory.create(
    keyPair: keyPair,
    relayUrl: 'wss://relay.damus.io',
  );
  await nostrSignaling.connect();

  final server = ErmesSignalingServer(
    nostrSignaling: nostrSignaling,
    accountId: accountId,
  );

  final handler = ErmesSignalingHandler.create(
    stunHandler,
    shspSocket,
    bookService,
  );

  final repository = ErmesSignalingRepository(server, handler);
  final service = ErmesSignalingService(repository);

  return _SignalingStack(
    keyPair: keyPair,
    service: service,
    repository: repository,
    server: server,
    handler: handler,
    rawSocket: rawSocket,
    bookService: bookService,
  );
}

void main() {
  group('ErmesSignalingService (real stack)', () {
    test(
      'should be connected after setup with real relay',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        await expectLater(stack.service.isConnected(), completion(isTrue));
        await stack.dispose();
      },
    );

    test(
      'should return account id matching Nostr public key',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        final id = await stack.service.getIdAccount();
        expect(id, equals(stack.keyPair.publicKey));
        await stack.dispose();
      },
    );

    test(
      'should complete destroy without error',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        await expectLater(stack.service.destroy(), completes);
        await stack.handler.destroy();
        stack.rawSocket.close();
      },
    );

    test(
      'should store onSignal callback',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        OnSignalCreateSocketCallbackInput? receivedInput;

        stack.service.onSignal((input) {
          receivedInput = input;
        });

        expect(stack.service.signalCallback, isNotNull);
        await stack.dispose();
      },
    );

    test(
      'should remove all listeners',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        stack.service.removeAllListeners();
        expect(stack.repository.onAnswerCallback, isNull);
        await stack.dispose();
      },
    );

    test(
      'should wire up repository onSignal callback on construction',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        expect(stack.repository.onAnswerCallback, isNotNull);
        await stack.dispose();
      },
    );

    // TODO(implement): getLastSignal()
    // - Dovrebbe restituire l'ultimo segnale ricevuto via _handleSignal
    // - Dovrebbe restituire null se nessun segnale è stato ancora ricevuto
    // - Dovrebbe aggiornarsi a ogni nuovo segnale in arrivo
    //
    // Una volta implementato getLastSignal() su ErmesSignalingService,
    // scrivere test come:
    //
    // test('should return null before any signal received') ...
    // test('should return last received signal') ...
    // test('should update on each new signal') ...

  });
}
