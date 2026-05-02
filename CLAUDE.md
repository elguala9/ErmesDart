# ErmesDart Project Guidelines

## Testing

### Automatic Docker Compose Startup
Tests can be run with automatic Docker Compose startup using the provided scripts:

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
- **531 tests passing** ✅
- **18 tests skipped** when Ganache is unavailable (ErmesSignalingServer integration tests)
- Tests gracefully skip Ganache-dependent tests if Docker is not available

### Test Organization
All tests are centralized in the `packages/ermes_test/` package:
- **No mocks** - Use real implementations only (per testing guidelines)
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
- **web3dart**: v3.0.1
- **cryptography**: For ECDH key exchange and AES encryption

## Important Notes

1. **Async Storage**: All send operations are async (storage operations must complete)
2. **Singleton Pattern**: Repository uses singleton storage to prevent cross-test contamination
3. **Ganache Tests**: Optional - gracefully skip when Docker is unavailable
4. **No Breaking Changes**: When modifying interfaces, update all implementations

## Hooks Configuration

For IDE integration with automatic Docker startup, add to your Claude Code settings:

```json
{
  "hooks": {
    "pre-test": "if command -v docker-compose >/dev/null; then docker-compose -f docker-compose-evm.yml up -d; fi"
  }
}
```

This will automatically start Ganache before running `dart test`.
