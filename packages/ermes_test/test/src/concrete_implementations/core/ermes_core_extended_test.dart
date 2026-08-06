import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void testErmesCoreExtended() {
  group('ErmesCore Extended', () {
    setUpAll(registerErmesStorageHandlers);

    // ========================================================================
    // ShspSocketFactoryHelper
    // ========================================================================
    group('ShspSocketFactoryHelper', () {
      test('createDefault binds to any IPv4 random port', () async {
        final socket = await ShspSocketFactoryHelper.createDefault();
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createIPv6 binds to any IPv6 random port', () async {
        final socket = await ShspSocketFactoryHelper.createIPv6();
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createWithPort binds to specified port', () async {
        final socket = await ShspSocketFactoryHelper.createWithPort(port: 0);
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createWithPort with ipv6 flag', () async {
        final socket = await ShspSocketFactoryHelper.createWithPort(
          port: 0,
          ipv6: true,
        );
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createWithAddress binds to custom address', () async {
        final socket = await ShspSocketFactoryHelper.createWithAddress(
          address: InternetAddress.loopbackIPv4,
          port: 0,
        );
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createForTesting binds to loopback', () async {
        final socket = await ShspSocketFactoryHelper.createForTesting();
        expect(socket, isA<IShspSocket>());
        socket.close();
      });

      test('createForTestingWithPort binds to loopback on specific port',
          () async {
        final socket =
            await ShspSocketFactoryHelper.createForTestingWithPort(0);
        expect(socket, isA<IShspSocket>());
        socket.close();
      });
    });

    // ========================================================================
    // OrcErmesAdvancedFactory
    // ========================================================================
    group('OrcErmesAdvancedFactory', () {
      IErmesSignalingHandler<ShspPeer> createHandler(IShspSocket s) =>
          ErmesSignalingHandler.create(
            testStunShspHandler(s),
            s,
            ErmesBookService(),
          );

      test('create returns OrcErmes with all deps', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = createHandler(socket);
        try {
          final orc = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
          );
          expect(orc, isA<OrcErmes>());
          await orc.destroy();
        } finally {
          socket.close();
        }
      });

      test('create with custom bookService', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = createHandler(socket);
        final bookService = ErmesBookService();
        try {
          final orc = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
            bookService: bookService,
          );
          expect(orc, isA<OrcErmes>());
          await orc.destroy();
        } finally {
          socket.close();
        }
      });

      test('create with encryption disabled', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = createHandler(socket);
        try {
          final orc = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
            enableEncryption: false,
          );
          expect(orc, isA<OrcErmes>());
          await orc.destroy();
        } finally {
          socket.close();
        }
      });

      test('create with custom timeout', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = createHandler(socket);
        try {
          final orc = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
            connectionTimeoutMs: 10000,
          );
          expect(orc, isA<OrcErmes>());
          await orc.destroy();
        } finally {
          socket.close();
        }
      });

      test('create can be called twice over the same socket, producing '
          'two independent OrcErmes instances', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = createHandler(socket);
        try {
          final first = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
          );
          final second = await OrcErmesAdvancedFactory.create(
            signalingServer: _createDummySignalingServer(),
            signalingHandler: signalingHandler,
            socket: socket,
          );
          expect(first, isNot(same(second)));
          await first.destroy();
          await second.destroy();
        } finally {
          socket.close();
        }
      });
    });

    // ========================================================================
    // ShspSocketFactoryHelper — Error Handling / Edge Cases
    // ========================================================================
    group('ShspSocketFactoryHelper Error Handling', () {
      test('createWithPort throws ShspValidationException for a negative '
          'port', () async {
        await expectLater(
          ShspSocketFactoryHelper.createWithPort(port: -1),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('createWithPort throws ShspValidationException for a port above '
          '65535', () async {
        await expectLater(
          ShspSocketFactoryHelper.createWithPort(port: 65536),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test('createForTestingWithPort throws ShspValidationException for a '
          'negative port', () async {
        await expectLater(
          ShspSocketFactoryHelper.createForTestingWithPort(-5),
          throwsA(isA<ShspValidationException>()),
        );
      });

      test(
          'BUG: createForTestingWithPort does NOT throw when the port is '
          'already bound to another socket — dart:io RawDatagramSocket.bind '
          'defaults to reuseAddress: true, and ShspSocketFactoryHelper never '
          'overrides it, so two independent sockets can silently share the '
          'same local port instead of failing fast. Not fixed here, only '
          'documented.', () async {
        final first = await ShspSocketFactoryHelper.createForTesting();
        final boundPort = first.localPort!;
        try {
          final second =
              await ShspSocketFactoryHelper.createForTestingWithPort(
            boundPort,
          );
          expect(second.localPort, equals(boundPort));
          second.close();
        } finally {
          first.close();
        }
      });

      test('socket close() is idempotent (double close does not throw)',
          () async {
        final socket = await ShspSocketFactoryHelper.createForTesting();
        socket.close();
        expect(socket.close, returnsNormally);
      });
    });
  });
}

void main() {
  testErmesCoreExtended();
}

ErmesSignalingServer _createDummySignalingServer() => ErmesSignalingServer(
    nostrSignaling: _DummyNostrSignaling(),
    accountId: 'test-account',
  );

class _DummyNostrSignaling extends INostrSignaling {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  bool isConnected() => false;

  @override
  Future<String> publish(List<int> data) async => 'dummy-event-id';

  @override
  Future<String> subscribe(
    NostrUserId id,
    covariant IEventCallback onEvent, {
    int? since,
  }) async =>
      'dummy-sub-id';

  @override
  Future<List<int>> retrieveLast(NostrUserId id) async => [];

  @override
  Future<void> unsubscribe(NostrUserId id) async {}

  @override
  Future<void> destroy() async {}

}
