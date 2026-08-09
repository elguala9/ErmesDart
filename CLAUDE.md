# ErmesDart Project Guidelines

## Testing

### Running Tests

**All platforms (melos):**
```bash
melos run test --no-select
```
(`--no-select` is required in non-interactive shells; without it melos prompts
for a package and crashes on a terminal it cannot read.)

**Shell wrapper (Linux/Mac):**
```bash
./scripts/run_tests.sh
```

**Direct Dart Test:**
```bash
dart test packages/ermes_test/test/
```

### Test Results
- **1861 tests passing** ✅ — `ermes_test` 1476, `ermes_test_with_mock` 101,
  `ermes_storage` 90, `ermes_cipher` 50, `ermes_signaling` 48,
  `ermes_id_handler` 47, `ermes_message_control` 34, `ermes_core_init` 12
- `ermes_signaling_service_test` publishes to a public Nostr relay and times out
  intermittently. Re-run before treating a failure there as a regression.

### Test Organization
- Tests are centralized in `packages/ermes_test/`
- **No mocks** - Use real implementations (mocks only in `ermes_test_with_mock`)
- Tests are written **against interfaces**, not implementations
- Tests must be callable as functions to work with any implementation
- Each class must have a corresponding test class
- Both success and error cases must be tested

## Project Structure

- `packages/ermes_core/` - Core messaging functionality
- `packages/ermes_signaling/` - Signaling server implementation
- `packages/ermes_cipher/` - Encryption/decryption support
- `packages/ermes_test/` - Centralized test suite
- `packages/ermes_test_with_mock/` - Tests requiring mocks
- `packages/ermes_storage/` - Persistent storage with encryption
- `packages/ermes_id_handler/` - Unique ID generation
- `packages/ermes_message_control/` - Message tracking & retransmission
- `packages/ermes_core_init/` - DI registration & initialisation
- `packages/iermes/` - Interface definitions (abstract classes)
- `scripts/` - Automated testing scripts

## Architecture

### Interface Segregation
- **Interfaces** live in `packages/iermes/` (a dedicated package)
- **Implementations** live in separate packages and **never** contain interfaces
- Implementations always reference interfaces, never the reverse

### Dart Coding Standards
- No `dynamic`, no `as` casts
- Prefer `factory` constructors for interface implementations
- Strongly typed code always
- Files ≤150 lines (excluding tests)
- Functions/methods ≤30 lines
- 0 errors and 0 warnings

### Factory Pattern
- Every class must have a dedicated factory
- Each factory takes an `Input` class with all required parameters
- Factories must be tested

### Dependency Injection (singleton_manager 2.x)

One keyed registry, `RegistryManager.instance`. There is no separate global
container: each `key` is an independent object graph, so two peers can be booted
side by side in one process. Use a distinct key per test to isolate state.

- Annotate an injectable class `@dependencyInjectable`, and declare its
  dependencies as **unnamed-constructor parameters**. The generator reads that
  constructor and writes a `dependencyInjectionFactory({key, subkey})` into the
  class. There are no `_di.dart` files and no `late` setter injection.
- Regenerate with `melos run singleton_generator` (or `melos run singleton_generator:<package>`
  for a single package). Defaults are ignored by the generator:
  a non-nullable parameter becomes `getInstance<T>` (throws when unregistered),
  a nullable one becomes `tryGetInstance<T>` (yields null). **So anything that
  should be optional under DI must be declared nullable**, with the default
  applied in the constructor body.
- `--registry-output` is deliberately not used: the file it emits only imports
  the implementations it found, so it cannot see the interfaces in
  `package:iermes`. Each package hand-maintains `lib/src/main_injection.dart`
  with a `MainInjection*Mixin` plus an injector that supplies the inputs the
  graph does not own.
- Registry lookups are keyed by the **exact** type. `IErmesSignalingHandler<ShspPeer>`
  and `IErmesSignalingHandler<IShspPeer>` are two different entries; where both
  are needed, register the concrete type once and have each interface entry
  resolve it, so the stack shares one instance.
- Sub-keys select between same-typed instances. stun_shsp and shsp register one
  `IStunShspHandler` / `IShspSocket` per address family under `'ipv4'` / `'ipv6'`;
  `@Subkey('ipv4')` on a constructor parameter is what pins today's
  IPv4-primary path.
- `packages/ermes_core_init/` composes the whole stack: `ErmesInjector` /
  `initializeErmes({key, ...})`. The former `initialPoint*` family is gone.

### Exception Handling
- Never return `null` for absent values — throw an exception
- Avoid `try-catch` unless strictly necessary
- Use a custom exception hierarchy (`ErmesException`, `ErmesNetworkException`, etc.)

## Key Dependencies

- **Dart SDK**: Latest stable
- **singleton_manager**: ^2.2.2 (+ `singleton_manager_generator` ^2.3.2)
- **stun_shsp**: ^0.4.0 (brings `stun` 1.6.1 and `shsp` 1.10.1)
- **nostr_signaling**: ^0.6.0
- **cryptography**: For ECDH key exchange and AES encryption

All four networking packages are pulled from sibling checkouts via
`dependency_overrides` in the root `pubspec.yaml`, so those sibling repos must
exist next to this one for `dart pub get` to resolve.

## Important Notes

1. **Async Storage**: All send operations are async (storage operations must complete)
2. **Singleton Pattern**: Repository uses singleton storage to prevent cross-test contamination
3. **No Breaking Changes**: When modifying interfaces, update all implementations
4. **No .bat/.ps1 scripts**: Prefer melos scripts defined in pubspec.yaml or package.json

## Speedy (Semantic Search)

Speedy MCP è configurato per questo progetto in `.claude/settings.json`. Usa i suoi tool per ricerche semantiche nel codebase prima di fare ricerche manuali con Grep/Glob.

| Tool MCP | Quando usarlo |
|---|---|
| `speedy_query` | Ricerca semantica in linguaggio naturale |
| `speedy_context` | Panoramica del progetto |
| `run_pipeline` | Analisi impatto per un task (preferire questo) |
| `get_skeleton` | Struttura file/simboli |

Prerequisito: Ollama deve essere in esecuzione (`ollama serve`) con modello `nomic-embed-text`.
