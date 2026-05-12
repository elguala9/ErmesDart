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
- **1447 tests passing** ✅

### Test Organization
Most of the tests are centralized in the `packages/ermes_test/` package:
- **No mocks** - Use real implementations only (per testing guidelines)
- Mocks allowed only in *_with_mocks
- Tests cover cipher, encryption/decryption, retransmission, and signaling

## Project Structure

- `packages/ermes_core/` - Core messaging functionality
- `packages/ermes_signaling/` - Signaling server implementation
- `packages/ermes_cipher/` - Encryption/decryption support
- `packages/ermes_test/` - Centralized test suite
- `scripts/` - Automated testing scripts

## Key Dependencies

- **Dart SDK**: Latest stable
- **nostr_signaling**: v0.2.0
- **cryptography**: For ECDH key exchange and AES encryption

## Important Notes

1. **Async Storage**: All send operations are async (storage operations must complete)
2. **Singleton Pattern**: Repository uses singleton storage to prevent cross-test contamination
3. **No Breaking Changes**: When modifying interfaces, update all implementations
