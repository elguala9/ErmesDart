import 'test_result.dart';

typedef TestFn = Future<void> Function();

class DockerTestRunner {
  DockerTestRunner({required this.peer});

  final String peer;
  final List<TestResult> _results = [];

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

  SuiteResult buildResult() => SuiteResult(
    peer: peer,
    tests: List.unmodifiable(_results),
    timestamp: DateTime.now().toUtc().toIso8601String(),
  );
}
