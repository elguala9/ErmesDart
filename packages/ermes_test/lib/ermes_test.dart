/// Centralized test suites for Ermes interfaces
///
/// This library provides test functions that verify implementations
/// comply with interface contracts. Each test suite tests an interface
/// without depending on specific implementations.
library ermes_test;

// Integration layer for easy package testing
export 'src/integration.dart';
// Individual test suites for manual use
export 'src/interface_tests/book_repository_test_suite.dart';
export 'src/interface_tests/signaling_repository_test_suite.dart';
export 'src/interface_tests/signaling_server_test_suite.dart';
export 'src/interface_tests/signaling_service_test_suite.dart';
