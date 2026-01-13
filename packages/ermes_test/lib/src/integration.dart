import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

import 'interface_tests/book_repository_test_suite.dart';
import 'interface_tests/signaling_repository_test_suite.dart';
import 'interface_tests/signaling_server_test_suite.dart';
import 'interface_tests/signaling_service_test_suite.dart';

/// Configuration for running interface tests
@includeInBarrelFile
class InterfaceTestConfig {
  const InterfaceTestConfig({required this.implementationName, this.groupName});

  /// Optional group name to organize tests
  final String? groupName;

  /// Name of the implementation being tested
  final String implementationName;
}

/// Factory functions for creating interface implementations
@includeInBarrelFile
class InterfaceFactories {
  const InterfaceFactories({
    this.signalingServer,
    this.signalingService,
    this.signalingRepository,
    this.bookRepository,
  });

  /// Factory for IErmesSignalingServer
  final IErmesSignalingServer Function()? signalingServer;

  /// Factory for IErmesSignalingService
  final IErmesSignalingService Function()? signalingService;

  /// Factory for IErmesSignalingRepository<T>
  final IErmesSignalingRepository<dynamic> Function()? signalingRepository;

  /// Factory for IErmesBookRepository<TInput, TInfo>
  final IErmesBookRepository<dynamic, dynamic> Function()? bookRepository;
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
@includeInBarrelFile
void runInterfaceTests({
  required InterfaceTestConfig config,
  required InterfaceFactories factories,
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

    if (factories.signalingRepository != null) {
      testIErmesSignalingRepository(
        config.implementationName,
        factories.signalingRepository!,
      );
    }

    if (factories.bookRepository != null) {
      testIErmesBookRepository<String, Map<String, dynamic>>(
        config.implementationName,
        factories.bookRepository!
            as IErmesBookRepository<String, Map<String, dynamic>> Function(),
      );
    }
  });
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
@includeInBarrelFile
void runSignalingServerTests({
  required InterfaceTestConfig config,
  required IErmesSignalingServer Function() factory,
}) {
  testIErmesSignalingServer(config.implementationName, factory);
}

@includeInBarrelFile
void runSignalingServiceTests({
  required InterfaceTestConfig config,
  required IErmesSignalingService Function() factory,
}) {
  testIErmesSignalingService(config.implementationName, factory);
}

@includeInBarrelFile
void runSignalingRepositoryTests({
  required InterfaceTestConfig config,
  required IErmesSignalingRepository<dynamic> Function() factory,
}) {
  testIErmesSignalingRepository(config.implementationName, factory);
}

@includeInBarrelFile
void runBookRepositoryTests<TInput, TInfo>({
  required InterfaceTestConfig config,
  required IErmesBookRepository<TInput, TInfo> Function() factory,
}) {
  testIErmesBookRepository<TInput, TInfo>(config.implementationName, factory);
}
