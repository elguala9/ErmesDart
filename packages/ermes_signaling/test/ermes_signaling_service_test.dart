
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

  final bookService = ErmesBookService()
    ..setAccount(AccountInfo<BookData>(
    account: accountId,
    peerInfo: ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: rawSocket.port,
      id: accountId,
    ),
  ));

  // stun_shsp 0.4.0 dropped StunShspHandlerSingleton; build a handler over the
  // socket this stack already owns so the two stay in sync.
  final stunHandler = StunShspHandler(ShspSocketMigratable(shspSocket));

  final nostrSignaling = NostrSignalingFactory.create(
    keyPair: keyPair,
    relayUrls: ['wss://relay.damus.io'],
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
        stack.service.onSignal((input) {
          // callback registered successfully
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
      'should throw when no last signal available',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        await expectLater(
          stack.service.getLastSignal(),
          throwsException,
        );
        await stack.dispose();
      },
    );

    test(
      'should return last received signal',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        final signal = SignalErmes(
          publicKey: 'test',
          ipv6: '',
          ipv6Port: '',
          ipv4: '127.0.0.1',
          ipv4Port: '9000',
        epochTimestampStartConversation: 1000,
        epochTimestampExpireConversation: 2000,
      );
        await stack.server.setSignal(signal, stack.keyPair.publicKey);
        await Future<void>.delayed(const Duration(seconds: 1));
        final lastSignal = await stack.service.getLastSignal();
        // After setSignal, the service may or may not have
        // received the signal depending on Nostr event timing
        expect(lastSignal, isA<ISignalErmes>());
        await stack.dispose();
      },
    );

    test(
      'should throw when no last signal available (forced)',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        await expectLater(
          stack.service.getLastSignalForced(),
          throwsException,
        );
        await stack.dispose();
      },
    );

    test(
      'should return last signal forced after setSignal',
      timeout: const Timeout(Duration(seconds: 30)),
      () async {
        final stack = await _createStack();
        final signal = SignalErmes(
          publicKey: 'test',
          ipv6: '',
          ipv6Port: '',
          ipv4: '127.0.0.1',
          ipv4Port: '9000',
        epochTimestampStartConversation: 1000,
        epochTimestampExpireConversation: 2000,
      );
        await stack.server.setSignal(signal, stack.keyPair.publicKey);
        await Future<void>.delayed(const Duration(seconds: 2));
        final lastSignal = await stack.service.getLastSignalForced();
        expect(lastSignal, isA<ISignalErmes>());
        await stack.dispose();
      },
    );

  });
}
