# ermes_id_handler

Monotonic ID generator with persistent storage for Ermes messages.

## Purpose

Produces unique, increasing IDs for outgoing messages and chunk references. Persists the current counter through `work_db` so IDs survive restarts.

## Public surface

- **`IdHandlerService`** — implements `IIdHandlerService` from `iermes`. Returns the next ID via `getNewId()`.
- **`IdHandlerRepository`** — in-memory counter; delegates persistence to the storage layer.
- **`IdHandlerStorageRepository` / `IdHandlerStorageService`** — `IIdHandlerStorage` implementations backed by `IWorkDbSync` (default: `MemoryWorkDb`).
- **Factories** — `IdHandlerFactory`, `IdHandlerServiceFactory`, `IdHandlerStorageFactory` with their `Input` classes.
- **DI bindings** — `IdHandlerServiceDI`, `IdHandlerStorageRepositoryDI`, `IdHandlerStorageServiceDI`.

## Notes

- The default WorkDb collection name is `id_handler`. Avoid creating a `packages/id_handler/` runtime folder by configuring a writable working directory before initialization (see `.gitignore`).

## Testing

Tests live alongside the package under `packages/ermes_id_handler/test/`.
