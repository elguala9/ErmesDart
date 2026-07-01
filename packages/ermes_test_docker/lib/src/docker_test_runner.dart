import 'test_result.dart';

/// Signature of an asynchronous test body executed by [DockerTestRunner].
typedef TestFn = Future<void> Function();

/// Runs named test cases for a single peer, timing each and collecting the
/// pass/fail outcomes into a [SuiteResult].
class DockerTestRunner {
  /// Creates a runner that labels results and logs with the given [peer] name.
  DockerTestRunner({required this.peer});

  /// Identifier of the peer these tests run as (e.g. `alice`).
  final String peer;

  /// Accumulated results, one per [run] invocation.
  final List<TestResult> _results = [];

  /// Executes [fn] under the label [name], recording its duration and whether
  /// it passed, and logging the outcome to stdout.
  Future<void> run(String name, TestFn fn) async {
    final sw = Stopwatch()..start();
    try {
      await fn();
      sw.stop();
      _results.add(TestResult(
        name: name,
        passed: true,
        durationMs: sw.elapsedMilliseconds,
      ));
      // ignore: avoid_print
      print(
        '[${peer.toUpperCase()}] PASS: $name (${sw.elapsedMilliseconds}ms)',
      );
    } on Exception catch (e) {
      sw.stop();
      _results.add(TestResult(
        name: name,
        passed: false,
        durationMs: sw.elapsedMilliseconds,
        error: e.toString(),
      ));
      // ignore: avoid_print
      print('[${peer.toUpperCase()}] FAIL: $name -> $e');
    }
  }

  /// Builds the aggregated [SuiteResult] for all tests run so far.
  SuiteResult buildResult() => SuiteResult(
    peer: peer,
    tests: List.unmodifiable(_results),
    timestamp: DateTime.now().toUtc().toIso8601String(),
  );
}
