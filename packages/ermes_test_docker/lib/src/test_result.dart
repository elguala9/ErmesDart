/// Outcome of a single test case: its name, pass/fail flag, duration and any
/// captured error message.
class TestResult {
  /// Creates a result; [error] is set only when the test failed.
  const TestResult({
    required this.name,
    required this.passed,
    required this.durationMs,
    this.error,
  });

  /// Name of the test case.
  final String name;

  /// Whether the test completed without throwing.
  final bool passed;

  /// Wall-clock execution time in milliseconds.
  final int durationMs;

  /// Error text captured when the test failed, otherwise `null`.
  final String? error;

  /// Serialises this result to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'name': name,
    'passed': passed,
    'duration_ms': durationMs,
    if (error != null) 'error': error,
  };
}

/// Aggregated results of all test cases run by one peer.
class SuiteResult {
  /// Creates a suite result for [peer] with its [tests] and capture
  /// [timestamp].
  SuiteResult({
    required this.peer,
    required this.tests,
    required this.timestamp,
  });

  /// Identifier of the peer that produced these results.
  final String peer;

  /// Individual test outcomes in execution order.
  final List<TestResult> tests;

  /// ISO-8601 UTC timestamp of when the suite finished.
  final String timestamp;

  /// Whether every test in the suite passed.
  bool get allPassed => tests.every((t) => t.passed);

  /// Number of tests that passed.
  int get passedCount => tests.where((t) => t.passed).length;

  /// Serialises the suite, including summary counts, to a JSON-compatible map.
  Map<String, Object?> toJson() => {
    'peer': peer,
    'timestamp': timestamp,
    'all_passed': allPassed,
    'passed': passedCount,
    'total': tests.length,
    'tests': tests.map((t) => t.toJson()).toList(),
  };
}
