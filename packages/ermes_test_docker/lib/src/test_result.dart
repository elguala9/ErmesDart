class TestResult {
  const TestResult({
    required this.name,
    required this.passed,
    required this.durationMs,
    this.error,
  });

  final String name;
  final bool passed;
  final int durationMs;
  final String? error;

  Map<String, Object?> toJson() => {
    'name': name,
    'passed': passed,
    'duration_ms': durationMs,
    if (error != null) 'error': error,
  };
}

class SuiteResult {
  SuiteResult({
    required this.peer,
    required this.tests,
    required this.timestamp,
  });

  final String peer;
  final List<TestResult> tests;
  final String timestamp;

  bool get allPassed => tests.every((t) => t.passed);
  int get passedCount => tests.where((t) => t.passed).length;

  Map<String, Object?> toJson() => {
    'peer': peer,
    'timestamp': timestamp,
    'all_passed': allPassed,
    'passed': passedCount,
    'total': tests.length,
    'tests': tests.map((t) => t.toJson()).toList(),
  };
}
