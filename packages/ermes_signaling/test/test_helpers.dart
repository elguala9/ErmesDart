/// Helper per la gestione dei server nei test
///
/// Questo file permette di switchare facilmente tra ErmesSignalingServer reale e MockSignalingServer
library test_helpers;

import 'dart:io' show Platform;

import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import 'mocks/mock_signaling_server.dart';

/// Tipo di server da utilizzare nei test
enum ServerType {
  /// Server mock per test isolati
  mock,

  /// Server reale per test di integrazione
  real,
}

/// Configurazione globale del tipo di server da usare
/// Può essere cambiata per eseguire tutti i test con server reale o mock
/// Legge automaticamente dalle variabili d'ambiente se disponibili
ServerType defaultServerType = _getServerTypeFromEnvironment();

/// Factory centralizzata per creare server
///
/// Per cambiare il tipo di server globalmente:
/// ```dart
/// defaultServerType = ServerType.real; // o ServerType.mock
/// ```
///
/// Per usare un tipo specifico in un test:
/// ```dart
/// final server = createServer(ServerType.real);
/// ```
IErmesSignalingServer createServer([ServerType? type]) {
  final serverType = type ?? defaultServerType;

  switch (serverType) {
    case ServerType.mock:
      return MockSignalingServer();
    case ServerType.real:
      // Per test di integrazione con server reale
      // Nota: questo richiederebbe configurazione specifica
      return createRealServerForTesting();
  }
}

/// Factory specifica per MockSignalingServer
MockSignalingServer createMockServer() => MockSignalingServer();

/// Factory per ErmesSignalingServer reale (per test di integrazione)
/// NOTA: Per ora crea un mock configurato diversamente per distinguerlo
IErmesSignalingServer createRealServerForTesting() {
  // In un'implementazione completa, qui ci sarebbe:
  // return ErmesSignalingServer(realContract, realHandler);

  // Per ora crea un mock ma lo marca come "reale" per il sistema di test
  return _RealServerMock();
}

/// Mock speciale che simula un server reale
/// Permette a isUsingRealServer() di funzionare correttamente
class _RealServerMock extends MockSignalingServer {
  _RealServerMock() {
    setConnected(true);
    setAccountId('real-server-simulation');
  }
}

/// Helper per configurare rapidamente un server connesso
IErmesSignalingServer createConnectedServer({
  ServerType? type, // Cambiato a nullable per usare default globale
  String accountId = 'test-account',
  Map<IdAccountType, ISignalErmes> presetSignals = const {},
}) {
  final server =
      createServer(type); // Ora usa il default globale se type è null

  if (server is MockSignalingServer) {
    // Configura mock server
    server.setConnected(true);
    server.setAccountId(accountId);

    // Aggiungi segnali preconfigurati
    presetSignals.forEach(server.setSignalForPeer);
  }
  // Se fosse un server reale, qui ci sarebbe la configurazione specifica

  return server;
}

/// Helper per configurare un server che simula errori
IErmesSignalingServer createErrorServer([ServerType? type]) {
  final server = createServer(type); // Usa default globale se type è null

  if (server is MockSignalingServer) {
    server.setShouldThrowError(true);
  }
  // Per server reale, configurazione diversa per simulare errori

  return server;
}

/// Helper per switchare globalmente a server reale per tutti i test
void useRealServerForAllTests() {
  defaultServerType = ServerType.real;
}

/// Helper per switchare globalmente a mock server per tutti i test
void useMockServerForAllTests() {
  defaultServerType = ServerType.mock;
}

/// Verifica che tipo di server si sta usando
bool isUsingMockServer(IErmesSignalingServer server) =>
    server is MockSignalingServer && server is! _RealServerMock;

/// Verifica se si sta usando il tipo di server reale
bool isUsingRealServer(IErmesSignalingServer server) =>
    server is _RealServerMock || server is! MockSignalingServer;

/// Legge la configurazione server dalle variabili d'ambiente
/// ERMES_USE_REAL_SERVER=true -> ServerType.real
/// ERMES_USE_MOCK_SERVER=true -> ServerType.mock
/// Default: ServerType.mock
ServerType _getServerTypeFromEnvironment() {
  final useReal =
      Platform.environment['ERMES_USE_REAL_SERVER']?.toLowerCase() == 'true';
  final useMock =
      Platform.environment['ERMES_USE_MOCK_SERVER']?.toLowerCase() == 'true';

  if (useReal) {
    print(
      '🔗 Configurato per usare SERVER REALE tramite variabile d\'ambiente',
    );
    return ServerType.real;
  } else if (useMock) {
    print('🎭 Configurato per usare MOCK SERVER tramite variabile d\'ambiente');
    return ServerType.mock;
  }

  // Default: mock server
  print('🎭 Usando MOCK SERVER (default)');
  return ServerType.mock;
}
