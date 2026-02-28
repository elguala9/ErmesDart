
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'interface_tests/book_repository_test_suite.dart';
import 'interface_tests/ermes_service_test_suite.dart';
import 'interface_tests/signaling_repository_test_suite.dart';
import 'interface_tests/signaling_server_test_suite.dart';
import 'interface_tests/signaling_service_test_suite.dart';

/// Configuration for running interface tests

class InterfaceTestConfig {
  const InterfaceTestConfig({required this.implementationName, this.groupName});

  /// Optional group name to organize tests
  final String? groupName;

  /// Name of the implementation being tested
  final String implementationName;
}

/// Factory functions for creating interface implementations

class InterfaceFactories<S> {
  const InterfaceFactories({
    this.signalingServer,
    this.signalingService,
    this.signalingRepository,
    this.service,
    this.repository,
    this.bookRepository,
  });

  /// Factory for IErmesSignalingServer
  final IErmesSignalingServer Function()? signalingServer;

  /// Factory for IErmesSignalingService
  final IErmesSignalingService Function()? signalingService;

  /// Factory for generic IErmesService
  final IErmesService Function()? service;

  /// Factory for IErmesSignalingRepository<T>
  final IErmesSignalingRepository<S> Function()? signalingRepository;

  /// Factory for IErmesRepository
  final IErmesRepository Function()? repository;

  /// Factory for IErmesBookRepository
  final IErmesBookRepository<Object> Function()? bookRepository;
}

/// Single entry point to run all interface tests for a package
///
/// Usage example in your package's test/integration_test.dart:
/// ```dart
/// import 'package:test/test.dart';
/// import 'package:ermes_test/ermes_test.dart';
/// import '../lib/my_implementations.dart';
///
/// void main() {
///   runInterfaceTests(
///     config: InterfaceTestConfig(
///       implementationName: 'MyPackage Implementation',
///       groupName: 'MyPackage Interface Tests',
///     ),
///     factories: InterfaceFactories(
///       signalingServer: () => MySignalingServer(),
///       signalingService: () => MySignalingService(),
///       signalingRepository: () => MySignalingRepository(),
///       bookRepository: () => MyBookRepository<String,
///           Map<String, dynamic>>(),
///     ),
///   );
/// }
/// ```

void runInterfaceTests<S>({
  required InterfaceTestConfig config,
  required InterfaceFactories<S> factories,
}) {
  final groupName =
      config.groupName ?? '${config.implementationName} Interface Tests';

  group(groupName, () {
    if (factories.signalingServer != null) {
      testIErmesSignalingServer(
        config.implementationName,
        factories.signalingServer!,
      );
    }

    if (factories.signalingService != null) {
      testIErmesSignalingService(
        config.implementationName,
        factories.signalingService!,
      );
    }

    if (factories.service != null && factories.repository != null) {
      // Create two service instances from the provided factory. The
      // implementation tests expect two already-initialized services that
      // can exchange messages.
      final svcA = factories.service!();
      final svcB = factories.service!();

      testIErmesService(config.implementationName, svcA, svcB);
    }

    if (factories.signalingRepository != null) {
      testIErmesSignalingRepository(
        config.implementationName,
        factories.signalingRepository!,
      );
    }

    if (factories.bookRepository != null) {
      testIErmesBookRepository(
        config.implementationName,
        factories.bookRepository!,
      );
    }
  });
}

/// Factory functions for multi-peer test scenarios

class MultiPeerFactories {
  const MultiPeerFactories({
    required this.createSignalingServer,
    required this.createIdHandler,
  });

  /// Factory for IErmesSignalingServer
  final IErmesSignalingServer Function() createSignalingServer;

  /// Factory for IIdHandlerService
  final IIdHandlerService Function() createIdHandler;
}

/// Run specific interface tests individually (for more control)
///
/// Usage example:
/// ```dart
/// void main() {
///   runSignalingServerTests(
///     config: InterfaceTestConfig(implementationName: 'MyServer'),
///     factory: () => MySignalingServer(),
///   );
/// }
/// ```

void runSignalingServerTests({
  required InterfaceTestConfig config,
  required IErmesSignalingServer Function() factory,
}) {
  testIErmesSignalingServer(config.implementationName, factory);
}


void runSignalingServiceTests({
  required InterfaceTestConfig config,
  required IErmesSignalingService Function() factory,
}) {
  testIErmesSignalingService(config.implementationName, factory);
}


void runSignalingRepositoryTests<S>({
  required InterfaceTestConfig config,
  required IErmesSignalingRepository<S> Function() factory,
}) {
  testIErmesSignalingRepository(config.implementationName, factory);
}


void runBookRepositoryTests<TInfo>({
  required InterfaceTestConfig config,
  required IErmesBookRepository<TInfo> Function() factory,
}) {
  testIErmesBookRepository(config.implementationName, factory);
}
