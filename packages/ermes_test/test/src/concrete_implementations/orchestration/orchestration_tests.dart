// Test aggregator for orchestration tests
// This file ensures all orchestration tests are discovered and run

import 'orc_ermes_test.dart' as orc_ermes;

Future<void> main() async {
  await orc_ermes.main();
}
