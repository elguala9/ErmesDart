import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void testErmesCoreExtended() {
  group('ErmesCore Extended', () {
    setUpAll(initialPointErmesStorage);

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

      test('createForTestingWithPort binds to loopback on specific port', () async {
        final socket = await ShspSocketFactoryHelper.createForTestingWithPort(0);
        expect(socket, isA<IShspSocket>());
        socket.close();
      });
    });

    // ========================================================================
    // ShspSocketHandler / ShspSocketHandlerSingleton
    // ========================================================================
    group('ShspSocketHandler', () {
      test('default constructor creates instance', () {
        final handler = ShspSocketHandler();
        expect(handler, isA<ShspSocketHandler>());
      });

      test('stunShspHandler returns singleton', () {
        final handler = ShspSocketHandler();
        expect(
          handler.stunShspHandler,
          same(StunShspHandlerSingleton.instance),
        );
      });
    });

    group('ShspSocketHandlerSingleton', () {
      test('instance returns same singleton', () {
        final a = ShspSocketHandlerSingleton.instance;
        final b = ShspSocketHandlerSingleton.instance;
        expect(identical(a, b), isTrue);
      });

      test('reset is a no-op', () {
        ShspSocketHandlerSingleton.reset();
        final instance = ShspSocketHandlerSingleton.instance;
        expect(instance, isA<ShspSocketHandlerSingleton>());
      });

      test('inherits from ShspSocketHandler', () {
        final instance = ShspSocketHandlerSingleton.instance;
        expect(instance, isA<ShspSocketHandler>());
      });
    });

    // ========================================================================
    // OrcErmesAdvancedFactory
    // ========================================================================
    group('OrcErmesAdvancedFactory', () {
      IErmesSignalingHandler<ShspPeer> _createHandler(IShspSocket s) {
        return ErmesSignalingHandler.create(
          StunShspHandlerSingleton.instance,
          s,
          ErmesBookService(),
        );
      }

      test('create returns OrcErmes with all deps', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final signalingHandler = _createHandler(socket);
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
        final signalingHandler = _createHandler(socket);
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
        final signalingHandler = _createHandler(socket);
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
        final signalingHandler = _createHandler(socket);
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
    });
  });
}

void main() {
  testErmesCoreExtended();
}

ErmesSignalingServer _createDummySignalingServer() {
  return ErmesSignalingServer(
    nostrSignaling: _DummyNostrSignaling(),
    accountId: 'test-account',
  );
}

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
  void destroy() {}

  @override
  void registerWith<T extends IValueForRegistry>() {}

  @override
  T? retrieveRegistration<T extends IValueForRegistry>() => null;
}
