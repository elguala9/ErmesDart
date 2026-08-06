import 'dart:io';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';
import '../../test_signaling_helper.dart';

void testErmesFactories() {
  group('Ermes Factories', () {
    setUpAll(registerErmesStorageHandlers);
    group('OrcErmesFactory', () {
      test('create returns OrcErmes instance', () async {
        final setup = await createTestSignalingSetup();
        try {
          final orc = OrcErmesFactory.create(
            signalingServer: setup.signalingServer,
            signalingHandler: setup.signalingHandler,
            socket: setup.shspSocket,
          );
          expect(orc, isA<OrcErmes>());
          await orc.destroy();
        } finally {
          await setup.dispose();
        }
      });
    });

    group('ErmesConnectionsHandlerFactory', () {
      test('createHandler returns ErmesConnectionsHandler', () {
        final handler = ErmesConnectionsHandlerFactory.createHandler();
        expect(handler, isA<ErmesConnectionsHandler>());
      });
    });

    group('ErmesConnectionFactory', () {
      test('createConnection factory exists', () {
        expect(ErmesConnectionFactory, isA<Type>());
      });
    });

    group('ErmesPeerFactory', () {
      test('create requires ErmesPeerConfig', () async {
        final setup = await createTestSignalingSetup();
        try {
          final config = ErmesPeerConfig(
            remotePeerId: setup.accountId,
            socket: setup.shspSocket,
            signalingHandler: setup.signalingHandler,
            ermesBookService: setup.bookService,
            idHandler: IdHandlerServiceFactory.createDefault(),
            timeoutMs: 5000,
            enableEncryption: false,
          );
          final peer = ErmesPeerFactory.create(config);
          expect(peer, isA<ErmesPeer>());
          await peer.dispose();
        } finally {
          await setup.dispose();
        }
      });
    });

    group('ErmesRepositoryFactory', () {
      test('create returns ErmesRepository', () async {
        final setup = await createTestSignalingSetup();
        try {
          final repo = ErmesRepositoryFactory.create(
            remotePeerId: setup.accountId,
            socket: setup.shspSocket,
            signalHandler: setup.signalingHandler,
            ermesBookService: setup.bookService,
          );
          expect(repo, isA<ErmesRepository>());
          repo.destroy();
        } finally {
          await setup.dispose();
        }
      });
    });

    group('ErmesServiceFactory', () {
      test('createService returns ErmesService', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer',
        );
        try {
          final idHandler = IdHandlerServiceFactory.createDefault();
          final service = ErmesServiceFactory.createService(
            100, 1024, repository, idHandler,
            null, null, null, null, null,
          );
          expect(service, isA<ErmesService>());
          service.close();
        } finally {
          repository.cleanUp();
        }
      });
    });

    group('ErmesSendRepoFactory', () {
      test('create returns ErmesSendRepo', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer',
        );
        try {
          final idHandler = IdHandlerServiceFactory.createDefault();
          final sendRepo = ErmesSendRepoFactory.create(
            repository: repository,
            idHandler: idHandler,
          );
          expect(sendRepo, isA<ErmesSendRepo>());
        } finally {
          repository.cleanUp();
        }
      });
    });

    group('ErmesReadRepoFactory', () {
      test('create returns ErmesReadRepo', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer',
        );
        try {
          final readRepo = ErmesReadRepoFactory.create(
            repository: repository,
            onServiceMessage: (msg) {},
            options: const ErmesReadRepoOptions(),
          );
          expect(readRepo, isA<ErmesReadRepo>());
        } finally {
          repository.cleanUp();
        }
      });
    });

    group('ErmesFactory', () {
      ErmesPeerInfo peerInfo(IdAccountType id) => ErmesPeerInfo(
            address: InternetAddress('127.0.0.1'),
            port: 9999,
            id: id,
          );

      void setupPeer(IErmesBookService<Object> bs, IdAccountType id) {
        (bs as ErmesBookServiceBase).setAccount(AccountInfo<BookData>(
          account: id,
          peerInfo: peerInfo(id),
        ));
      }

      test('createRepository returns ErmesRepository instance', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler(
          testStunShspHandler(socket),
          socket,
          ErmesBookService(),
        );
        final bookService = ErmesBookService();
        setupPeer(bookService, 'test-peer-id');
        try {
          final factory = ErmesFactory(ermesBookService: bookService);
          final repo = factory.createRepository(
            'test-peer-id',
            socket,
            handler,
          );
          expect(repo, isA<ErmesRepository>());
          repo.destroy();
        } finally {
          socket.close();
        }
      });

      test('createRepository uses custom timeout', () async {
        final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
        final handler = ErmesSignalingHandler(
          testStunShspHandler(socket),
          socket,
          ErmesBookService(),
        );
        final bookService = ErmesBookService();
        setupPeer(bookService, 'test-peer-id');
        try {
          final factory = ErmesFactory(
            ermesBookService: bookService,
            defaultTimeoutMs: 5000,
          );
          final repo = factory.createRepository(
            'test-peer-id',
            socket,
            handler,
            10000,
          );
          expect(repo, isA<ErmesRepository>());
          repo.destroy();
        } finally {
          socket.close();
        }
      });

      test('createService returns ErmesService instance', () async {
        final repository = await TestErmesRepository.create(
          peerId: 'test-peer',
        );
        try {
          final factory = ErmesFactory(ermesBookService: ErmesBookService());
          final service = factory.createService(repository);
          expect(service, isA<ErmesService>());
          service.close();
        } finally {
          repository.cleanUp();
        }
      });

      test('implements interface correctly', () async {
        final bookService = ErmesBookService();
        final factory = ErmesFactory(ermesBookService: bookService);
        expect(factory.ermesBookService, same(bookService));
        expect(factory.defaultTimeoutMs, equals(30000));
      });

      test('custom defaultTimeoutMs is applied', () async {
        final factory = ErmesFactory(
          ermesBookService: ErmesBookService(),
          defaultTimeoutMs: 15000,
        );
        expect(factory.defaultTimeoutMs, equals(15000));
      });
    });

    // ========================================================================
    // Error Handling / Edge Cases
    // ========================================================================
    group('Error Handling and Edge Cases', () {
      group('ErmesServiceFactory boundary', () {
        test('maxByte exactly at the default max (1024) succeeds', () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final service = ErmesServiceFactory.createService(
              100, 1024, repository, IdHandlerServiceFactory.createDefault(),
              null, null, null, null, null,
            );
            expect(service, isA<ErmesService>());
            service.close();
          } finally {
            repository.cleanUp();
          }
        });

        test('maxByte one over the default max (1025) throws ArgumentError',
            () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            expect(
              () => ErmesServiceFactory.createService(
                100, 1025, repository, IdHandlerServiceFactory.createDefault(),
                null, null, null, null, null,
              ),
              throwsA(isA<ArgumentError>()),
            );
          } finally {
            repository.cleanUp();
          }
        });

        test('null maxByte falls back to the default max size', () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final service = ErmesServiceFactory.createService(
              null, null, repository, IdHandlerServiceFactory.createDefault(),
              null, null, null, null, null,
            );
            expect(service, isA<ErmesService>());
            service.close();
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('ErmesSendRepoFactory boundary', () {
        test('maxByte one under the throw threshold (1199) succeeds',
            () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final sendRepo = ErmesSendRepoFactory.create(
              repository: repository,
              idHandler: IdHandlerServiceFactory.createDefault(),
              maxByte: 1199,
            );
            expect(sendRepo, isA<ErmesSendRepo>());
          } finally {
            repository.cleanUp();
          }
        });

        test(
            'BUG: maxByte of 1200 throws ArgumentError even though the '
            'message claims the limit is 1299 — ErmesSendRepo enforces '
            '"maxByte >= 1200" while its own error text says "cannot be '
            'more than 1299". Not fixed here, only documented.', () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            expect(
              () => ErmesSendRepoFactory.create(
                repository: repository,
                idHandler: IdHandlerServiceFactory.createDefault(),
                maxByte: 1200,
              ),
              throwsA(isA<ArgumentError>()),
            );
          } finally {
            repository.cleanUp();
          }
        });
      });

      group('ErmesRepositoryFactory missing peer info', () {
        test('create throws CoreException when the book service has no '
            'entry for the remote peer', () async {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          final emptyBookService = ErmesBookService();
          final handler = ErmesSignalingHandler(
            testStunShspHandler(socket),
            socket,
            emptyBookService,
          );
          try {
            expect(
              () => ErmesRepositoryFactory.create(
                remotePeerId: 'never-registered-peer',
                socket: socket,
                signalHandler: handler,
                ermesBookService: emptyBookService,
              ),
              throwsA(isA<CoreException>()),
            );
          } finally {
            socket.close();
          }
        });
      });

      group('ErmesFactory.createRepository missing peer info', () {
        test('throws CoreException when the book service has no entry for '
            'the remote peer', () async {
          final socket =
              await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
          final emptyBookService = ErmesBookService();
          final handler = ErmesSignalingHandler(
            testStunShspHandler(socket),
            socket,
            emptyBookService,
          );
          final factory = ErmesFactory(ermesBookService: emptyBookService);
          try {
            expect(
              () => factory.createRepository(
                'never-registered-peer',
                socket,
                handler,
              ),
              throwsA(isA<CoreException>()),
            );
          } finally {
            socket.close();
          }
        });
      });

      group('ErmesConnectionFactory', () {
        test('createConnection wires signaling handler, repository and '
            'connection id', () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final connection = ErmesConnectionFactory.createConnection(
              _StubSignalingHandler(),
              repository,
              'test-peer',
            );
            expect(connection, isA<ErmesConnection>());
            expect(connection.getIdConnection(), equals('test-peer'));
            expect(connection.getIErmesRepository(), same(repository));
          } finally {
            repository.cleanUp();
          }
        });

        test('destroyConnection is idempotent (double call does not throw)',
            () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final connection = ErmesConnectionFactory.createConnection(
              _StubSignalingHandler(),
              repository,
              'test-peer',
            );
            await connection.destroyConnection();
            await expectLater(
              connection.destroyConnection(),
              completes,
            );
          } finally {
            repository.cleanUp();
          }
        });

        test('resetReconnectAttempts does not throw when no attempts have '
            'been made', () async {
          final repository =
              await TestErmesRepository.create(peerId: 'test-peer');
          try {
            final connection = ErmesConnectionFactory.createConnection(
              _StubSignalingHandler(),
              repository,
              'test-peer',
            );
            expect(connection.resetReconnectAttempts, returnsNormally);
          } finally {
            repository.cleanUp();
          }
        });
      });
    });
  });
}

void main() {
  testErmesFactories();
}

/// Minimal real (non-framework-mock) signaling handler used only to satisfy
/// [ErmesConnectionFactory.createConnection]'s `IErmesSignalingHandler<
/// IShspSocket>` parameter — the only concrete implementation in the
/// codebase, [ErmesSignalingHandler], implements
/// `IErmesSignalingHandler<ShspPeer>` instead, and Dart generics are
/// invariant, so it cannot be passed here directly.
class _StubSignalingHandler implements IErmesSignalingHandler<IShspSocket> {
  @override
  Future<void> clearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) async {}

  @override
  Future<List<IdAccountType>> getAllPeerIds() async => [];

  @override
  Future<ISignalErmes> createSignal([
    IdAccountType? remotePeerId,
    String? localPublicKey,
  ]) async =>
      throw UnimplementedError();

  @override
  Future<void> processSignal(
    ISignalErmes signal,
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<IShspSocket> callback,
  ) async {}

  @override
  Future<SocketDto<IShspSocket>> getSocket(IdAccountType of) async =>
      throw UnimplementedError();

  @override
  Future<bool> isSocketReady(IdAccountType of) async => false;

  @override
  Future<SocketDto<IShspSocket>> waitForConnect(
    IdAccountType peerId,
    int ms,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> destroy() async {}
}
