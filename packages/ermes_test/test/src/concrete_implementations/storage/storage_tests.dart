// Aggregates all storage package tests
// Previously located in packages/ermes_storage/test/
// Consolidated in ermes_test for centralized testing

import 'caching_repository_test.dart' as caching_repo;
import 'caching_service_test.dart' as caching_svc;
import 'edge_cases_and_factories_test.dart' as edge_cases;
import 'integration_test.dart' as integration;
import 'storage_repository_test.dart' as storage_repo;
import 'storage_service_test.dart' as storage_svc;

void testErmesStorage() {
  // Run all storage tests
  caching_repo.main();
  caching_svc.main();
  edge_cases.main();
  integration.main();
  storage_repo.main();
  storage_svc.main();
}
