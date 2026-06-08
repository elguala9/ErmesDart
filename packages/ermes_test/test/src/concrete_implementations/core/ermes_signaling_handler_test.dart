import 'dart:async';
import 'dart:io';

import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void testErmesSignalingHandler() {
  group('ErmesSignalingHandler', () {
    group('constructor variants', () {
      test('default constructor creates instance', () {
        final handler = ErmesSignalingHandler();
        expect(handler, isA<ErmesSignalingHandler>());
      });

      test('emptyForDI creates instance', () {
        final handler = ErmesSignalingHandler.emptyForDI();
        expect(handler, isA<ErmesSignalingHandler>());
      });

      test('create constructor with all params', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        expect(handler, isA<ErmesSignalingHandler>());
        await handler.destroy();
        socket.close();
      });

      test('create constructor with overridePort', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
          overridePort: 9999,
        );
        expect(handler, isA<ErmesSignalingHandler>());
        await handler.destroy();
        socket.close();
      });
    });

    group('setCustomStunServer', () {
      test('accepts host and port', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        )..setCustomStunServer('stun.l.google.com', 19302);
        await handler.destroy();
        socket.close();
      });
    });

    group('connection management', () {
      late ShspSocket socket;
      late ErmesSignalingHandler handler;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
      });

      tearDown(() async {
        await handler.destroy();
        socket.close();
      });

      test('getAllPeerIds returns empty list initially', () async {
        final ids = await handler.getAllPeerIds();
        expect(ids, isEmpty);
      });

      test('isSocketReady returns false for unknown peer', () async {
        final ready = await handler.isSocketReady('unknown-peer');
        expect(ready, isFalse);
      });

      test('getSocket throws for unknown peer', () async {
        expect(
          () => handler.getSocket('unknown-peer'),
          throwsA(isA<Exception>()),
        );
      });

      test('clearConnection does not throw for unknown peer', () async {
        await handler.clearConnection('unknown-peer');
      });

      test('softClearConnection does not throw for unknown peer', () async {
        await handler.softClearConnection('unknown-peer');
      });

      test('clearConnection is idempotent', () async {
        await handler.clearConnection('unknown-peer');
        await handler.clearConnection('unknown-peer');
      });

      test('softClearConnection is idempotent', () async {
        await handler.softClearConnection('unknown-peer');
        await handler.softClearConnection('unknown-peer');
      });
    });

    group('onSocketReady', () {
      late ShspSocket socket;
      late ErmesSignalingHandler handler;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
      });

      tearDown(() async {
        await handler.destroy();
        socket.close();
      });

      test('registers callback for future connection', () async {
        var callbackCalled = false;
        await handler.onSocketReady('peer-1', (_) {
          callbackCalled = true;
        });
        expect(callbackCalled, isFalse);
      });

      test('registers multiple callbacks for same peer', () async {
        var callCount = 0;
        await handler.onSocketReady('peer-1', (_) {
          callCount++;
        });
        await handler.onSocketReady('peer-1', (_) {
          callCount++;
        });
        expect(callCount, equals(0));
      });
    });

    group('waitForConnect', () {
      late ShspSocket socket;
      late ErmesSignalingHandler handler;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
      });

      tearDown(() async {
        await handler.destroy();
        socket.close();
      });

      test('throws TimeoutException when connection not established', () async {
        expect(
          () => handler.waitForConnect('unknown-peer', 100),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('implements IErmesSignalingHandler', () {
      test('default handler implements interface', () {
        final handler = ErmesSignalingHandler();
        expect(handler, isA<IErmesSignalingHandler<ShspPeer>>());
      });

      test('emptyForDI handler implements interface', () {
        final handler = ErmesSignalingHandler.emptyForDI();
        expect(handler, isA<IErmesSignalingHandler<ShspPeer>>());
      });

      test('create handler implements interface', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        expect(handler, isA<IErmesSignalingHandler<ShspPeer>>());
        await handler.destroy();
        socket.close();
      });
    });

    group('processSignal', () {
      late ShspSocket socket;
      late ErmesSignalingHandler handler;
      late ErmesBookService bookService;

      setUp(() async {
        socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        bookService = ErmesBookService();
        handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          bookService,
        );
      });

      tearDown(() async {
        await handler.destroy();
        socket.close();
      });

      test('throws when signal has no IP address', () async {
        final signal = SignalErmes(
          publicKey: '',
          ipv6: '',
          ipv6Port: '',
          ipv4: '',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 0,
        );
        expect(
          () => handler.processSignal(signal, 'test-peer', (_) {}),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when signal has only empty IP strings', () async {
        final signal = SignalErmes(
          publicKey: '',
          ipv6: '::',
          ipv6Port: '',
          ipv4: '0.0.0.0',
          ipv4Port: '',
          epochTimestampStartConversation: 0,
          secondsIntervalWindow: 0,
          epochTimestampExpireConversation: 0,
        );
        expect(
          () => handler.processSignal(signal, 'test-peer', (_) {}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('destroy', () {
      test('cleans up all resources', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        await handler.destroy();
        final ids = await handler.getAllPeerIds();
        expect(ids, isEmpty);
      });
    });

    group('createSignal', () {
      setUpAll(() async {
        if (!StunShspHandlerSingleton.instance.isInitialized) {
          await StunShspHandlerSingleton.instance.initialize();
        }
      });

      test('returns ISignalErmes with local fallback', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        try {
          final signal = await handler.createSignal();
          expect(signal, isA<ISignalErmes>());
          expect(signal.publicKey, isEmpty);
        } finally {
          await handler.destroy();
          socket.close();
        }
      });

      test('createSignal returns non-expired signal', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        try {
          final signal = await handler.createSignal();
          expect(signal.isExpired(), isFalse);
        } finally {
          await handler.destroy();
          socket.close();
        }
      });

      test('createSignal with remotePeerId returns valid signal', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        try {
          final signal =
              await handler.createSignal('some-remote-peer');
          expect(signal, isA<ISignalErmes>());
          expect(signal.isExpired(), isFalse);
        } finally {
          await handler.destroy();
          socket.close();
        }
      });
    });

    group('edge cases and lifecycle', () {
      test('destroy clears all socket-ready callbacks', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        var callbackCalled = false;
        await handler.onSocketReady('peer-1', (_) {
          callbackCalled = true;
        });
        await handler.destroy();
        expect(callbackCalled, isFalse);
        socket.close();
      });

      test('clearConnection after destroy is safe', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        await handler.destroy();
        await handler.clearConnection('peer-1');
        socket.close();
      });

      test('softClearConnection after destroy is safe', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        await handler.destroy();
        await handler.softClearConnection('peer-1');
        socket.close();
      });

      test('multiple destroy calls are safe', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          socket,
          ErmesBookService(),
        );
        await handler.destroy();
        await handler.destroy();
        socket.close();
      });


    });
  });
}

void main() {
  testErmesSignalingHandler();
}
