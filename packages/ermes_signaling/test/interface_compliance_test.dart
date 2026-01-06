import 'package:ermes_test/ermes_test.dart';

import 'mocks/mock_signaling_server.dart';

/// Integration tests for ermes_signaling package implementations
///
/// This file tests that our mock implementations conform to the interfaces
/// using the centralized test suites from ermes_test package.
///
/// Note: We use mocks here because the real implementations require
/// complex dependencies (blockchain contracts, etc.)
void main() {
  // Test using the available mock server
  runSignalingServerTests(
    config: const InterfaceTestConfig(
      implementationName: 'MockSignalingServer',
    ),
    factory: MockSignalingServer.new,
  );

  // Example of how to add more interface tests when implementations are available
  // with proper mocking or dependency injection
}
