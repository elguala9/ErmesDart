import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';
import '../../test_signaling_helper.dart';

void testErmesFactories() {
  group('Ermes Factories', () {
    setUpAll(initialPointErmesStorage);
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
            messageControlService: null,
            options: const ErmesReadRepoOptions(),
          );
          expect(readRepo, isA<ErmesReadRepo>());
        } finally {
          repository.cleanUp();
        }
      });
    });
  });
}

void main() {
  testErmesFactories();
}
