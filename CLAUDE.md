# ErmesDart Project Guidelines

## Testing

### Running Tests

**Linux/Mac:**
```bash
./scripts/run_tests.sh
```

**Windows:**
```bash
scripts\run_tests.bat
```

**Direct Dart Test:**
```bash
dart test packages/ermes_test/test/
```

### Test Results
- **1453 tests passing** ✅

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

### Exception Handling
- Never return `null` for absent values — throw an exception
- Avoid `try-catch` unless strictly necessary
- Use a custom exception hierarchy (`ErmesException`, `ErmesNetworkException`, etc.)

## Key Dependencies

- **Dart SDK**: Latest stable
- **nostr_signaling**: v0.2.0
- **cryptography**: For ECDH key exchange and AES encryption

## Important Notes

1. **Async Storage**: All send operations are async (storage operations must complete)
2. **Singleton Pattern**: Repository uses singleton storage to prevent cross-test contamination
3. **No Breaking Changes**: When modifying interfaces, update all implementations
4. **No .bat/.ps1 scripts**: Prefer melos scripts defined in pubspec.yaml or package.json
