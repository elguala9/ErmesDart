import 'dart:convert';
import 'dart:io';

import 'test_result.dart';

/// Persists a [SuiteResult] as indented JSON into the configured directory.
class ResultWriter {
  /// Creates a writer that emits result files into [outputDir].
  const ResultWriter({required this.outputDir});

  /// Directory where per-peer result JSON files are written.
  final String outputDir;

  /// Writes [result] as `<peer>_result.json` under [outputDir], creating the
  /// directory if needed.
  Future<void> write(SuiteResult result) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('$outputDir/${result.peer}_result.json');
    final json = const JsonEncoder.withIndent('  ').convert(result.toJson());
    await file.writeAsString(json);
    // ignore: avoid_print
    print('[${result.peer.toUpperCase()}] Results written to ${file.path}');
  }
}
