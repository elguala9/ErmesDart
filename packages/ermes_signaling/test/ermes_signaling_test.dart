import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'mocks/mock_signaling_server.dart';
import 'test_helpers.dart';

void main() {
  group('Ermes Signaling Package Tests', () {
    late IErmesSignalingServer mockServer;

    setUp(() {
      mockServer = MockSignalingServer();
    });

    group('Test Helpers Demo', () {
      test('should create mock server by default', () {
        final server = createServer();
        expect(isUsingMockServer(server), isTrue);
        expect(server, isA<MockSignalingServer>());
      });

      test('should create mock server explicitly', () {
        final server = createServer(ServerType.mock);
        expect(isUsingMockServer(server), isTrue);
        expect(server, isA<MockSignalingServer>());
      });

      test('should create real server explicitly', () {
        final server = createServer(ServerType.real);
        // Per ora è una simulazione di server reale tramite mock
        expect(server, isA<IErmesSignalingServer>());
      });

      test('should create connected server with presets', () {
        final server = createConnectedServer(
          accountId: 'connected-user',
          presetSignals: {'peer1': 'signal_data_1'},
        );

        expect(isUsingMockServer(server), isTrue);
        final mockServer = server as MockSignalingServer;
        expect(mockServer.accountId, equals('connected-user'));
      });

      test('should create error server', () {
        final server = createErrorServer();
        expect(isUsingMockServer(server), isTrue);
        expect(server, isA<MockSignalingServer>());
      });

      test('should switch default server type', () {
        // Salva stato originale
        final originalType = defaultServerType;

        // Test switch a real
        useRealServerForAllTests();
        expect(defaultServerType, equals(ServerType.real));
        final realServer = createServer();
        expect(isUsingRealServer(realServer), isTrue);

        // Test switch a mock
        useMockServerForAllTests();
        expect(defaultServerType, equals(ServerType.mock));
        final mockServer = createServer();
        expect(isUsingMockServer(mockServer), isTrue);

        // Ripristina stato
        defaultServerType = originalType;
      });
    });

    group('MockSignalingServer', () {
      test('should initialize correctly', () {
        expect(mockServer, isNotNull);
        expect(mockServer, isA<IErmesSignalingServer>());
      });

      test('should handle connection state', () async {
        // Initially disconnected
        expect(await mockServer.isConnected(), isFalse);

        // Configure connected state
        (mockServer as MockSignalingServer).setConnected(true);
        expect(await mockServer.isConnected(), isTrue);
      });

      test('should handle account ID', () async {
        const testAccountId = 'test-account-123';

        // Set account ID
        (mockServer as MockSignalingServer).setAccountId(testAccountId);

        // Get account ID
        final accountId = await mockServer.getIdAccount();
        expect(accountId, equals(testAccountId));
      });

      test('should handle signal operations', () async {
        const testSignal = 'test-signal-data';
        const targetPeer = 'target-peer-id';

        // Set signal
        await mockServer.setSignal(testSignal, targetPeer);

        // Verify signal was stored
        final mockServerInstance = mockServer as MockSignalingServer;
        expect(mockServerInstance.setSignalCalled, isTrue);
        expect(mockServerInstance.lastSetSignalValue, equals(testSignal));
        expect(mockServerInstance.lastSetSignalTarget, equals(targetPeer));
      });

      test('should handle get signal', () async {
        const fromPeer = 'from-peer-id';
        const expectedSignal = 'expected-signal';

        // Setup signal for peer
        (mockServer as MockSignalingServer)
            .setSignalForPeer(fromPeer, expectedSignal);

        // Get signal
        final signal = await mockServer.getSignal(fromPeer);
        expect(signal, equals(expectedSignal));

        // Verify tracking
        final mockServerInstance = mockServer as MockSignalingServer;
        expect(mockServerInstance.getSignalCalled, isTrue);
        expect(mockServerInstance.lastGetSignalFrom, equals(fromPeer));
      });

      test('should handle signal callbacks', () async {
        String? receivedSignal;

        // Register callback
        mockServer.onSignal((signal) {
          receivedSignal = signal;
        });

        // Verify callback registration
        final mockServerInstance = mockServer as MockSignalingServer;
        expect(mockServerInstance.onSignalCalled, isTrue);

        // Trigger callback
        const testSignal = 'callback-test-signal';
        mockServerInstance.triggerSignalCallback(testSignal);

        // Verify callback was called
        expect(receivedSignal, equals(testSignal));
      });

      test('should handle error conditions', () async {
        // Configure to throw error
        (mockServer as MockSignalingServer).setShouldThrowError(true);

        // Verify error is thrown
        expect(
          () => mockServer.getSignal('any-peer'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle cleanup', () async {
        // Destroy server
        await mockServer.destroy();

        // Verify destroy was called
        expect((mockServer as MockSignalingServer).destroyCalled, isTrue);
      });

      test('should remove all listeners', () async {
        // Add listener
        mockServer.onSignal((signal) {});

        // Remove all listeners
        await mockServer.removeAllListeners();

        // Verify removal
        expect(
          (mockServer as MockSignalingServer).removeAllListenersCalled,
          isTrue,
        );
      });
    });

    group('ErmesBookRepository', () {
      test('should initialize correctly', () {
        final repository = ErmesBookRepository();
        expect(repository, isNotNull);
        expect(repository, isA<ErmesBookRepository>());
      });

      test('should handle empty repository', () {
        final repository = ErmesBookRepository();
        expect(repository.numberOfElements(), equals(0));
      });
    });

    group('Factory Classes', () {
      test('ErmesBookFactories should create repository', () {
        final repository = ErmesBookFactories.createRepository();
        expect(repository, isNotNull);
        expect(repository, isA<ErmesBookRepository>());
      });
    });

    group('Mock Replacement Guide', () {
      test('should demonstrate easy mock replacement', () {
        // Questo test dimostra come sostituire facilmente il mock

        // 1. Usa sempre IErmesSignalingServer (non MockSignalingServer direttamente)
        final IErmesSignalingServer server = MockSignalingServer();
        expect(server, isA<IErmesSignalingServer>());

        // 2. Per sostituire il mock, basta cambiare la creazione:
        // IErmesSignalingServer server = MyNewMock(); // <- Nuova implementazione

        // 3. Il mock può essere configurato tramite casting quando necessario
        (server as MockSignalingServer).setConnected(true);
        server.setAccountId('replacement-demo');

        // 4. Le funzionalità base rimangono accessibili tramite interfaccia
        expect(server.isConnected(), completion(isTrue));
        expect(server.getIdAccount(), completion('replacement-demo'));
      });

      test('should show factory pattern for mock creation', () {
        // Usa il factory method per creare mock
        final server = MockSignalingServer.createMock();
        expect(server, isA<IErmesSignalingServer>());

        // Funziona esattamente come creazione diretta
        (server as MockSignalingServer).setConnected(true);
        expect(server.isConnected(), completion(isTrue));
      });
    });

    group('Configuration Examples', () {
      test('should show different mock configurations', () async {
        final mockInstance = mockServer as MockSignalingServer;

        // Configurazione 1: Server connesso con account
        mockInstance.setConnected(true);
        mockInstance.setAccountId('config-test-1');
        expect(await mockServer.isConnected(), isTrue);
        expect(await mockServer.getIdAccount(), 'config-test-1');

        // Configurazione 2: Server con segnali preconfigurati
        mockInstance.setSignalForPeer('peer1', 'signal-for-peer1');
        mockInstance.setSignalForPeer('peer2', 'signal-for-peer2');
        expect(await mockServer.getSignal('peer1'), 'signal-for-peer1');
        expect(await mockServer.getSignal('peer2'), 'signal-for-peer2');

        // Configurazione 3: Server che simula errori
        mockInstance.setShouldThrowError(true);
        expect(() => mockServer.getSignal('error-peer'), throwsException);
      });
    });
  });
}
