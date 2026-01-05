/// Esempio di utilizzo del sistema flessibile Server Real/Mock
///
/// Questo file dimostra come utilizzare il nuovo sistema per switchare
/// tra MockSignalingServer e ErmesSignalingServer a piacere
library flexible_server_example;

import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Esempi di Utilizzo Flessibile', () {
    group('Esempio 1: Test Specifici con Server Diversi', () {
      test('Test con mock server per test unitari', () {
        // Usa esplicitamente il mock per test unitari veloci
        final server = createServer(ServerType.mock);

        // Verifica che sia mock
        expect(isUsingMockServer(server), isTrue);

        // Test specifico del comportamento mock
        // Il mock non ha dipendenze esterne e è veloce
        print('✅ Test unitario con MockSignalingServer');
      });

      test('Test con server reale per test di integrazione', () {
        // Usa il server reale per test di integrazione
        final server = createServer(ServerType.real);

        // Verifica che sia configurato come server reale
        expect(isUsingRealServer(server), isTrue);

        // Test di integrazione più realistici
        print('✅ Test di integrazione con server reale (simulato)');
      });
    });

    group('Esempio 2: Configurazione Globale', () {
      test('Esecuzione di tutti i test con mock', () {
        // Configura tutti i test per usare mock
        useMockServerForAllTests();

        // Tutti questi server saranno mock
        final server1 = createServer();
        final server2 = createConnectedServer();
        final server3 = createErrorServer();

        expect(isUsingMockServer(server1), isTrue);
        expect(isUsingMockServer(server2), isTrue);
        expect(isUsingMockServer(server3), isTrue);

        print('✅ Tutti i server sono mock (veloce per sviluppo)');
      });

      test('Esecuzione di tutti i test con server reali', () {
        // Configura tutti i test per usare server reali
        useRealServerForAllTests();

        // Questi server useranno l'implementazione reale
        final server1 = createServer();
        final server2 = createConnectedServer();

        expect(isUsingRealServer(server1), isTrue);
        expect(isUsingRealServer(server2), isTrue);

        print('✅ Tutti i server sono reali (test di integrazione completi)');

        // Ripristina a mock per altri test
        useMockServerForAllTests();
      });
    });

    group('Esempio 3: Scenari Pratici', () {
      test('Test rapido in sviluppo (usa mock)', () {
        // Durante lo sviluppo, usa mock per velocità
        final server = createMockServer();
        server.setConnected(true);
        server.setAccountId('dev-user');

        // Test rapido senza dipendenze esterne
        expect(server.accountId, equals('dev-user'));

        print('✅ Test di sviluppo veloce completato');
      });

      test('Test pre-release (usa server reale)', () {
        // Prima del release, testa con comportamento reale
        final server = createServer(ServerType.real);

        // Test che il server sia configurato correttamente
        expect(server, isA<IErmesSignalingServer>());

        print('✅ Test pre-release con server reale completato');
      });

      test('Test con server preconfigurato', () {
        // Crea server già configurato per scenario specifico
        final server = createConnectedServer(
          type: ServerType.mock, // Puoi cambiare a ServerType.real
          accountId: 'scenario-user',
          presetSignals: {
            'peer1': 'video_offer',
            'peer2': 'audio_answer',
          },
        );

        // Il server è già configurato e pronto per il test
        expect(isUsingMockServer(server), isTrue);

        print('✅ Test con server preconfigurato completato');
      });
    });

    group('Esempio 4: Pattern CI/CD', () {
      test('Configurazione basata su environment', () {
        // In un sistema reale potresti leggere da variabili ambiente:
        // final useReal = Platform.environment['USE_REAL_SERVER'] == 'true';
        // final serverType = useReal ? ServerType.real : ServerType.mock;

        // Per questo esempio, usiamo mock
        const serverType = ServerType.mock;
        final server = createServer(serverType);

        if (serverType == ServerType.mock) {
          print('✅ CI/CD: Eseguendo test veloci con mock server');
        } else {
          print('✅ CI/CD: Eseguendo test completi con server reale');
        }

        expect(server, isA<IErmesSignalingServer>());
      });
    });
  });
}

/// Funzione helper per dimostrare utilizzo in codice reale
void demonstrateFlexibleUsage() {
  print('\n=== Dimostrazione Uso Flessibile ===');

  // Scenario 1: Sviluppo rapido
  print('1. Sviluppo rapido con mock:');
  useMockServerForAllTests();
  final devServer = createConnectedServer(accountId: 'dev-test');
  print('   Server creato: ${isUsingMockServer(devServer) ? 'Mock' : 'Real'}');

  // Scenario 2: Test di integrazione
  print('2. Test di integrazione con server reale:');
  useRealServerForAllTests();
  final integrationServer = createServer();
  print(
      '   Server creato: ${isUsingRealServer(integrationServer) ? 'Real' : 'Mock'}');

  // Scenario 3: Test specifico
  print('3. Test specifico con scelta manuale:');
  final specificServer = createServer(ServerType.mock);
  print(
      '   Server creato: ${isUsingMockServer(specificServer) ? 'Mock (scelto)' : 'Real (scelto)'}');

  print('=== Fine Dimostrazione ===\n');
}
