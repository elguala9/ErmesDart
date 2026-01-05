/// Esempio di come sostituire MockSignalingServer con un'altra implementazione
///
/// Questo file dimostra la semplicità di sostituzione del mock
library mock_replacement_example;

import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'mocks/mock_signaling_server.dart';

/// Esempio di implementazione alternativa di IErmesSignalingServer
class AlternativeMockServer implements IErmesSignalingServer {
  bool _connected = false;
  String _accountId = 'alternative-mock';

  @override
  Future<void> destroy() async {}

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Future<String> getIdAccount() async => _accountId;

  @override
  Future<void> setSignal(String signal, [String? to]) async {}

  @override
  Future<String> getSignal(String from) async => 'alternative-signal-$from';

  @override
  void onSignal(void Function(String) callback, [String? from]) {}

  @override
  void onError(void Function(Object) callback) {}

  @override
  void onClose(void Function() callback) {}

  @override
  Future<void> removeAllListeners() async {}

  // Metodi di configurazione specifici per questa implementazione
  void setConnected(bool connected) => _connected = connected;
  void setAccountId(String accountId) => _accountId = accountId;
}

void main() {
  group('Mock Replacement Examples', () {
    group('Using Original MockSignalingServer', () {
      late IErmesSignalingServer server;

      setUp(() {
        server = MockSignalingServer(); // <- Implementazione originale
      });

      test('should work with original mock', () async {
        (server as MockSignalingServer).setAccountId('original-test');
        expect(await server.getIdAccount(), 'original-test');
      });
    });

    group('Using Alternative Mock Implementation', () {
      late IErmesSignalingServer server;

      setUp(() {
        server = AlternativeMockServer(); // <- Nuova implementazione
      });

      test('should work with alternative mock', () async {
        (server as AlternativeMockServer).setAccountId('alternative-test');
        expect(await server.getIdAccount(), 'alternative-test');
      });
    });

    group('Factory Pattern for Mock Creation', () {
      test('can switch mock implementations via factory', () {
        // Factory per creazione mock - può essere cambiata facilmente
        IErmesSignalingServer createMock() {
          // return MockSignalingServer(); // <- Originale
          return AlternativeMockServer(); // <- Alternativo
        }

        final server = createMock();
        expect(server, isA<IErmesSignalingServer>());
        expect(server,
            isA<AlternativeMockServer>()); // Verifica che sia il tipo alternativo
      });
    });
  });
}

/// Guida rapida per la sostituzione:
/// 
/// 1. **Per sostituire in un singolo test:**
///    ```dart
///    setUp(() {
///      server = MyNewMock(); // Invece di MockSignalingServer()
///    });
///    ```
/// 
/// 2. **Per sostituire globalmente:**
///    Modifica il metodo `createMockServer()` in test_helpers.dart
/// 
/// 3. **Per creare una nuova implementazione:**
///    ```dart
///    class MyCustomMock implements IErmesSignalingServer {
///      // Implementa tutti i metodi richiesti
///    }
///    ```
/// 
/// 4. **Vantaggi dell'approccio:**
///    - ✅ Sostituzione semplice e pulita
///    - ✅ Nessun cambiamento nei test esistenti
///    - ✅ Interfaccia garantisce compatibilità
///    - ✅ Mock configurabili per scenari specifici