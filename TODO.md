# TODO - Workspace summary

Questo file contiene un riepilogo rapido delle interfacce definite nel pacchetto `iermes` e lo stato delle implementazioni trovate nel workspace.

- IErmesRepository: implementazione di produzione in `ermes_core` ([packages/ermes_core/lib/src/ermes_repository.dart]) e esempi/mocks in `iermes` README.
- IErmesService: implementazione di produzione in `ermes_core` ([packages/ermes_core/lib/src/ermes_service.dart]).
- IErmesConnection: implementazione di produzione in `ermes_core` ([packages/ermes_core/lib/src/ermes_connection.dart]) e dummy in test.
- IErmesConnectionsHandler: implementazione di produzione in `ermes_core` ([packages/ermes_core/lib/src/ermes_connections_handler.dart]).
- IErmesMessageControlRepository/Service: implementazioni in `ermes_core`.
- IOrcErmes: nessuna implementazione trovata nel workspace.
- IIdHandlerRepository/Service/Storage: implementazioni in `ermes_core`.
- IErmesSignalingRepository/Service/Server: implementazioni in `ermes_signaling`.
- IErmesBookRepository: implementazione in `ermes_signaling`.
- IErmesBookService: nessuna implementazione trovata.
- Storage/Caching interfaces: disponibili in `iermes`, implementazioni non trovate (solo esempi/mocks).
 - IErmesBookRepository: implementazione in `ermes_signaling`.
 - IErmesBookService: nessuna implementazione trovata.
 - Storage/Caching interfaces: disponibili in `iermes`; implementazioni concrete presenti in `ermes_storage` (es. ErmesStorageRepository, ErmesCachingRepository, ErmesCachingService, ErmesStorageAndCaching).

Azioni suggerite:
- Aggiungere implementazioni per `IOrcErmes` e `IErmesBookService` se richieste.
- Creare documentazione dettagliata con riferimenti ai file (posso generarla se vuoi).

(Generato automaticamente dall'analisi dello workspace.)

Factory summary:

- ErmesFactory: implementata in `ermes_core` ([packages/ermes_core/lib/src/factories/ermes_factory.dart]).
- ErmesRepositoryFactory: implementata in `ermes_core` ([packages/ermes_core/lib/src/factories/ermes_repository_factory.dart]).
- ErmesServiceFactory: implementata in `ermes_core` ([packages/ermes_core/lib/src/factories/ermes_service_factory.dart]).
- ErmesConnectionFactory: implementata in `ermes_core` ([packages/ermes_core/lib/src/factories/ermes_connection_factory.dart]).
- ErmesConnectionsHandlerFactory: implementata in `ermes_core` ([packages/ermes_core/lib/src/factories/ermes_connections_handler_factory.dart]).
- ErmesReadRepoFactory / ErmesSendRepoFactory / ErmesMessageControlFactory: implementate in `ermes_core` (`lib/src/factories`).
- IdHandlerFactory / IdHandlerServiceFactory / IdHandlerStorageFactory: implementate in `ermes_core` (`lib/src/id_handler` and `lib/src/ermes_utility`).
- ErmesSignalingFactory / ErmesSignalingServerFactory / ErmesBookFactories: implementate in `ermes_signaling` (`lib/src/factories`).
- ErmesStorage factories: implementate in `ermes_storage` (`lib/src/factories/ermes_storage_factories.dart`, `ermes_caching_factories.dart`, `ermes_caching_storage_factories.dart`).

Missing / not found:

- IOrcErmes factory: non ho trovato una factory dedicata per `IOrcErmes`.
- IErmesBookService factory: non ho trovato una factory dedicata per `IErmesBookService` (anche se `ErmesBookRepository` e relativi factory esistono).

Se vuoi, posso:

- A) aggiungere i link con range di linee per ogni file factory nella `TODO.md`.
- B) creare boilerplate di factory mancanti (`IOrcErmes` e `IErmesBookService`) con implementazione provvisoria.
- C) aprire una PR con `TODO.md` aggiornato.
