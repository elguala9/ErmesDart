/// Esempi pratici di utilizzo del sistema flessibile server real/mock
///
/// Questo file mostra patterns di utilizzo comuni per sviluppatori
library practical_usage_examples;

import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'mocks/mock_signaling_server.dart';
import 'test_helpers.dart';

/// Esempio completo: Come utilizzare il sistema in progetti reali
void main() {
  group('Patterns di Utilizzo Pratico', () {
    group('Pattern 1: Suite di Test Mista', () {
      // Setup: alcuni test con mock, altri con server reale

      group('Unit Tests (Veloci)', () {
        test('logica di business con mock', () {
          // Forza mock per test unitari veloci
          final server = createServer(ServerType.mock);

          // Test della logica senza dipendenze esterne
          expect(isUsingMockServer(server), isTrue);
          print('🚀 Unit test completato velocemente');
        });

        test('edge case handling', () {
          final errorServer = createErrorServer(ServerType.mock);
          expect(isUsingMockServer(errorServer), isTrue);
          print('⚡ Test edge case completato');
        });
      });

      group('Integration Tests (Completi)', () {
        test('flusso completo end-to-end', () {
          // Usa server reale per test di integrazione
          final server = createServer(ServerType.real);

          expect(isUsingRealServer(server), isTrue);
          print('🔗 Test di integrazione completato');
        });
      });
    });

    group('Pattern 2: Configurazione per Environment', () {
      test('sviluppo locale (sempre mock)', () {
        // In sviluppo, sempre mock per velocità
        useMockServerForAllTests();

        final devServer = createConnectedServer(accountId: 'dev-user');
        expect(isUsingMockServer(devServer), isTrue);

        print('👨‍💻 Ambiente di sviluppo: mock attivo');
      });

      test('CI/CD pipeline (configurabile)', () {
        // In CI/CD potresti voler usare server reale per validazione finale
        // Simuliamo la scelta basata su variabile ambiente

        const isProductionTest =
            false; // In realtà: Platform.environment['PROD_TESTS'] == 'true'

        if (isProductionTest) {
          useRealServerForAllTests();
          print('🏭 CI/CD: Test di produzione con server reale');
        } else {
          useMockServerForAllTests();
          print('⚡ CI/CD: Test veloci con mock');
        }

        final ciServer = createServer();
        const expectedMock = !isProductionTest;
        expect(isUsingMockServer(ciServer), equals(expectedMock));
      });
    });

    group('Pattern 3: Test Parametrici', () {
      // Test che possono girare sia con mock che con server reale

      void runServerTest(String testName, ServerType serverType) {
        test('$testName con ${serverType.name} server', () {
          final server = createServer(serverType);

          // Test che funziona con entrambi i tipi
          expect(server, isA<IErmesSignalingServer>());

          final serverTypeName = isUsingMockServer(server) ? 'mock' : 'real';
          print('✅ $testName eseguito con server $serverTypeName');
        });
      }

      // Esegui lo stesso test con entrambi i tipi
      runServerTest('connessione base', ServerType.mock);
      runServerTest('connessione base', ServerType.real);

      runServerTest('gestione segnali', ServerType.mock);
      runServerTest('gestione segnali', ServerType.real);
    });

    group('Pattern 4: Lifecycle dei Test', () {
      late IErmesSignalingServer server;

      setUpAll(() {
        // Configurazione globale per tutto il gruppo
        print('🏗️ Setup: Configurando ambiente di test...');
        useMockServerForAllTests(); // O useRealServerForAllTests()
      });

      setUp(() {
        // Server fresh per ogni test
        server = createConnectedServer(
          accountId: 'test-session-${DateTime.now().millisecondsSinceEpoch}',
        );
      });

      tearDown(() async {
        // Cleanup dopo ogni test
        await server.destroy();
        print('🧹 Cleanup del server completato');
      });

      test('test con lifecycle gestito', () {
        expect(server, isNotNull);
        expect(isUsingMockServer(server), isTrue);
        print('♻️ Test con lifecycle automatico');
      });
    });

    group('Pattern 5: Test di Performance', () {
      test('benchmark mock vs real', () async {
        // Misura performance con mock
        final stopwatch1 = Stopwatch()..start();
        final mockServer = createServer(ServerType.mock);
        await mockServer.isConnected();
        stopwatch1.stop();

        // Misura performance con server reale
        final stopwatch2 = Stopwatch()..start();
        final realServer = createServer(ServerType.real);
        await realServer.isConnected();
        stopwatch2.stop();

        print('⏱️ Mock: ${stopwatch1.elapsedMicroseconds}μs');
        print('⏱️ Real: ${stopwatch2.elapsedMicroseconds}μs');

        // Verifica che entrambi siano ragionevolmente veloci (meno di 1ms)
        expect(stopwatch1.elapsedMicroseconds, lessThan(1000));
        expect(stopwatch2.elapsedMicroseconds, lessThan(1000));

        print('✅ Entrambi i server sono performanti per i test');

        await mockServer.destroy();
        await realServer.destroy();
      });
    });
  });
}

/// Esempi di utility functions che possono essere utilizzate nei progetti
class TestingUtilities {
  /// Crea un server configurato per test di connessione
  static IErmesSignalingServer createConnectionTestServer() =>
      createConnectedServer(
        accountId: 'connection-test',
        presetSignals: {
          'test-peer': 'connection-signal',
        },
      );

  /// Crea un server configurato per test di segnalazione
  static IErmesSignalingServer createSignalingTestServer() =>
      createConnectedServer(
        accountId: 'signaling-test',
        presetSignals: {
          'peer1': 'offer-signal',
          'peer2': 'answer-signal',
          'peer3': 'ice-candidate',
        },
      );

  /// Verifica che un server sia configurato correttamente
  static Future<void> assertServerReady(IErmesSignalingServer server) async {
    expect(await server.isConnected(), isTrue);
    expect(await server.getIdAccount(), isNotEmpty);
    print('✅ Server verificato e pronto per test');
  }

  /// Simula uno scenario di signaling completo
  static Future<void> simulateSignalingScenario(
      IErmesSignalingServer server) async {
    // Setup callback per ricevere segnali
    String? receivedSignal;
    server.onSignal((signal) {
      receivedSignal = signal;
    });

    // Simula invio segnale se è un mock
    if (server is MockSignalingServer) {
      server.triggerSignalCallback('test-signal');
      expect(receivedSignal, equals('test-signal'));
      print('📡 Scenario signaling completato con mock');
    } else {
      print('📡 Scenario signaling preparato per server reale');
    }
  }
}
