# ermes_test

Centralized interface testing package for the Ermes ecosystem. This package provides comprehensive test suites for all Ermes interfaces, allowing implementations across different packages to verify their conformance to interface contracts.

## Purpose

Instead of having implementation-specific tests scattered across packages, `ermes_test` provides:

- **Interface-focused testing**: Tests verify that implementations conform to interface contracts
- **Reusable test suites**: Write once, use across all implementing packages 
- **Centralized maintenance**: Updates to interface tests are automatically available to all packages
- **Consistent testing**: All implementations are tested with the same comprehensive test scenarios

## Supported Interfaces

- `IErmesSignalingServer` - Signaling server interface tests
- `IErmesSignalingService` - Signaling service interface tests  
- `IErmesSignalingRepository<T>` - Signaling repository interface tests
- `IErmesBookRepository<TInput, TInfo>` - Book repository interface tests

**Note**: Interface tests are designed to work with any implementation. Some interfaces like reconnectors are implemented as concrete classes rather than interfaces in the current codebase, so they don't have centralized interface tests.

## Usage

### Simple Integration (Recommended)

Add `ermes_test` as a dev dependency in your `pubspec.yaml`:

```yaml
dev_dependencies:
  test: ^1.24.0
  ermes_test:
    path: ../ermes_test  # Adjust path as needed
```

Create an integration test file (e.g., `test/interface_compliance_test.dart`):

```dart
import 'package:test/test.dart';
import 'package:ermes_test/ermes_test.dart';
import '../lib/my_implementations.dart';

void main() {
  runInterfaceTests(
    config: InterfaceTestConfig(
      implementationName: 'MyPackage Implementation',
      groupName: 'MyPackage Interface Tests',
    ),
    factories: InterfaceFactories(
      signalingServer: () => MySignalingServer(),
      signalingService: () => MySignalingService(),
      signalingRepository: () => MySignalingRepository(),
      signalingReconnector: () => MySignalingReconnector(),
      bookRepository: () => MyBookRepository<String, Map<String, dynamic>>(),
    ),
  );
}
```

### Individual Test Suites

For more granular control, you can run individual test suites:

```dart
import 'package:test/test.dart';
import 'package:ermes_test/ermes_test.dart';
import '../lib/my_signaling_server.dart';

void main() {
  runSignalingServerTests(
    config: InterfaceTestConfig(implementationName: 'MySignalingServer'),
    factory: () => MySignalingServer(),
  );
}
```

### Manual Test Suite Usage

You can also call test suites directly for maximum control:

```dart
import 'package:test/test.dart';
import 'package:ermes_test/ermes_test.dart';
import '../lib/my_implementation.dart';

void main() {
  testIErmesSignalingServer(
    'MyCustomServer',
    () => MySignalingServer(),
  );
}
```

## Test Coverage

Each test suite provides comprehensive coverage including:

### Common Test Areas
- Basic functionality and operations
- Error handling and edge cases  
- State management and transitions
- Integration scenarios
- Performance considerations
- Null safety and type safety

### Interface-Specific Tests

#### IErmesSignalingServer
- Connection management
- Signal handling and routing
- Event lifecycle
- Server lifecycle
- Multi-client scenarios

#### IErmesSignalingService  
- Service operations
- Signal processing
- Service lifecycle
- Error resilience

#### IErmesSignalingRepository<T>
- Generic type support
- CRUD operations
- Data consistency
- Repository patterns

#### IErmesSignalingReconnector
- Reconnection logic
- Backoff strategies
- Configuration management
- State transitions

#### IErmesBookRepository<TAccount, TInfo>
- Account management
- Pagination support
- Generic type handling
- CRUD workflows

## Running Tests

```bash
# Run all interface tests
dart test test/interface_compliance_test.dart

# Run with verbose output
dart test test/interface_compliance_test.dart -r expanded

# Run specific test groups
dart test test/interface_compliance_test.dart --name "SignalingServer"
```

## Example Implementation

See `packages/ermes_signaling/test/interface_compliance_test.dart` for a complete example of how the ermes_signaling package uses this testing framework.

## Benefits

1. **DRY Principle**: Write interface tests once, reuse everywhere
2. **Consistency**: All implementations tested with identical scenarios  
3. **Interface Compliance**: Catch interface violations early
4. **Maintainability**: Update tests in one place, affects all packages
5. **Documentation**: Tests serve as executable interface documentation
6. **Confidence**: Comprehensive testing increases reliability

## Architecture

```
ermes_test/
├── lib/
│   ├── ermes_test.dart              # Main export file
│   ├── src/
│   │   ├── integration.dart         # Easy integration layer
│   │   └── interface_tests/         # Individual test suites
│   │       ├── signaling_server_test_suite.dart
│   │       ├── signaling_service_test_suite.dart
│   │       ├── signaling_repository_test_suite.dart
│   │       ├── signaling_reconnector_test_suite.dart
│   │       └── book_repository_test_suite.dart
└── test/
    └── ermes_test_test.dart         # Tests for the test package itself
```

The integration layer (`integration.dart`) provides the `runInterfaceTests()` function for easy one-line integration, while individual test suites can be used directly for more control.

## Contributing

When adding new interfaces or extending existing ones:

1. Create corresponding test suites in `lib/src/interface_tests/`
2. Export new test suites in `lib/ermes_test.dart`
3. Add factory support in `integration.dart`
4. Update this README with new interface documentation
5. Test your changes across implementing packages

## Dependencies

- `package:test` - Dart testing framework
- `package:ermes_types` - Ermes type definitions
- `package:iermes` - Ermes interface definitions