import 'dart:convert';
import 'dart:io';

import 'test_result.dart';

class ResultWriter {
  const ResultWriter({required this.outputDir});

  final String outputDir;

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
