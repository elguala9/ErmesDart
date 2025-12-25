# Ermes Storage - Traduzione Dart

Traduzione completa del progetto TypeScript `ermes-storage` in Dart, mantenendo la stessa struttura e coerenza architettonica.

## Struttura del Progetto

```
lib/
├── ermes_storage.dart           # Barrel file (esportazioni principali)
└── src/
    ├── interfaces/              # Interfacce astratte
    │   ├── iermes_caching.dart
    │   ├── iermes_storage.dart
    │   ├── iermes_storage_and_caching.dart
    │   └── iermes_storage_reserved.dart
    ├── caching_implementation/  # Implementazione del caching in memoria
    │   ├── ermes_caching_repository.dart
    │   └── ermes_caching_service.dart
    ├── storage_implementation/  # Implementazione dello storage persistente
    │   ├── ermes_storage_repository.dart
    │   └── ermes_storage_service.dart
    ├── ermes_storage_and_caching.dart  # Sistema combinato
    ├── ermes_storage_type.dart         # Type aliases
    └── factories/               # Factory functions
        ├── ermes_caching_factories.dart
        ├── ermes_caching_storage_factories.dart
        └── ermes_storage_factories.dart
```

## Mapping TypeScript → Dart

### Concetti Chiave

| TypeScript | Dart |
|-----------|------|
| `interface` | `abstract class` |
| `type` | `typedef` |
| `class implements Interface` | `class extends AbstractClass` |
| `Promise<T>` | `Future<T>` |
| `async/await` | `async/await` |
| `Map<K, V>` | `Map<K, V>` |
| `undefined` | `null` / `?` |
| `any` | `dynamic` |
| Enum (`"fifo" \| "lifo"`) | `enum CachingMode { fifo, lifo }` |
| Generico `<T>` | Generico `<T>` |

### Equivalenze Importanti

```typescript
// TypeScript
interface IExample<T> {
  store(data: T): Promise<void>;
  retrieve(id: IdType): Promise<T | undefined>;
}

// Dart
abstract class IExample<T> {
  Future<void> store(T data);
  Future<T?> retrieve(dynamic id);
}
```

## Utilizzo di Base

```dart
import 'package:ermes_storage/ermes_storage.dart';

void main() async {
  // Creare il database (da adattare alla tua libreria)
  final db = await initializeDatabase();

  // Creare il sistema combinato di storage e caching
  final storageAndCaching = createErmesStorageAndCaching<MessageType>(
    db,
    collection: "messages",
    maxNumberOfElementCached: 100,
    cachingMode: CachingMode.fifo,
  );

  // Usare il sistema
  await storageAndCaching.store(myMessage);
  final retrieved = await storageAndCaching.retrieve(messageId);
  await storageAndCaching.flush(); // Svuota cache → storage persistente
}
```

## Differenze Rispetto a TypeScript

### 1. **Dependency Injection Esterna**
TypeScript include `ClientWorkDB` da una libreria esterna. In Dart abbiamo usato `dynamic` come placeholder:
```dart
ErmesStorageRepository<T>(dynamic db, [String collection = defaultCollection])
```
**Adattamento richiesto**: Rimpiazza `dynamic` con l'interfaccia reale del tuo database.

### 2. **Type System Più Rigoroso**
Dart ha un type system meno permissivo di TypeScript:
- `undefined` diventa `null` o `?`
- Assunzioni sulla struttura di `DataJson` devono essere esplicite

### 3. **Garbage Collection Automatico**
TypeScript nel codice nullava i riferimenti manualmente:
```typescript
// @ts-expect-error we want to null the reference to indicate destruction
this._db = null;
```
In Dart il GC automatico gestisce questo, quindi non è necessario.

### 4. **Costruttori con Named Parameters**
```dart
// Dart: più leggibile con named parameters
ErmesStorageAndCaching(
  storage,
  caching,
  maxNumberOfElementCached: 100,
  cachingMode: CachingMode.fifo,
)
```

### 5. **Async/Await**
Identico tra i due linguaggi, quindi la logica asincrona è praticamente la stessa.

## Prossimi Passi di Adattamento

1. **Integrare una libreria di database reale**
   - Sostituire `dynamic` con l'interfaccia concreta
   - Implementare i metodi commentati di create/read/update/delete

2. **Gestire i tipi di messaggi**
   - Rimpiazza `dynamic` nei type alias con i tipi concreti
   - Crea estensioni o wrapper se necessario

3. **Aggiungere test unit**
   - Copia la logica dei test TypeScript
   - Adatta per Dart testing (`test` package)

4. **Serializzazione JSON**
   - Se necessaria, usa `json_serializable` o equivalenti
   - Gestisci `toJson()` / `fromJson()` per i tuoi tipi

## Note Architetturali

La struttura mantiene la **separazione delle responsabilità** del progetto TypeScript:
- **Repositories**: Accesso dati (cache in memoria o storage persistente)
- **Services**: Logica di business, delegano ai repository
- **Factories**: Creazione e configurazione delle istanze
- **Combined System**: Coordina storage e caching con politiche di eviction

L'architettura è **fortemente tipizzata** con generici che supportano qualsiasi tipo di dato.

## Licenza e Crediti

Traduzione fedele del progetto `@parresia/ermes-storage` (TypeScript) → Dart.
Mantiene la stessa struttura logica, nomenclatura e flow dei dati.
