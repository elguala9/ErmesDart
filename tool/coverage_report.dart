#!/usr/bin/env dart
// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) async {
  print('📊 Code Coverage Report Generator');
  print('');

  final lcovFile = File('coverage/lcov.info');

  if (!lcovFile.existsSync()) {
    print('❌ coverage/lcov.info not found!');
    print('   Run: ./scripts/coverage.sh  (or coverage.bat on Windows)');
    exit(1);
  }

  final content = await lcovFile.readAsString();
  final report = _parseLcov(content);

  _printReport(report, args.contains('--untested'));
}

class _FileCoverage {

  _FileCoverage({
    required this.filePath,
    required this.totalLines,
    required this.testedLines,
    required this.unterstedLineNumbers,
  });
  final String filePath;
  final int totalLines;
  final int testedLines;
  final List<int> unterstedLineNumbers;

  double get coverage => totalLines == 0 ? 0 : (testedLines / totalLines) * 100;

  String get fileName => filePath.split('/').last;

  String get shortPath {
    final parts = filePath.split('/');
    if (parts.length > 3) {
      return '.../${parts.sublist(parts.length - 3).join('/')}';
    }
    return filePath;
  }
}

Map<String, _FileCoverage> _parseLcov(String content) {
  final files = <String, _FileCoverage>{};
  var currentFile = '';
  var totalLines = 0;
  var testedLines = 0;
  final unterstedLines = <int>[];
  final lineData = <int, int>{}; // line number -> execution count

  for (final line in content.split('\n')) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length == 2) {
        final lineNum = int.parse(parts[0]);
        final execCount = int.parse(parts[1]);
        lineData[lineNum] = execCount;
        totalLines++;
        if (execCount > 0) {
          testedLines++;
        } else {
          unterstedLines.add(lineNum);
        }
      }
    } else if (line == 'end_of_record') {
      if (currentFile.isNotEmpty && totalLines > 0) {
        files[currentFile] = _FileCoverage(
          filePath: currentFile,
          totalLines: totalLines,
          testedLines: testedLines,
          unterstedLineNumbers: unterstedLines,
        );
      }
      currentFile = '';
      totalLines = 0;
      testedLines = 0;
      unterstedLines.clear();
      lineData.clear();
    }
  }

  return files;
}

void _printReport(Map<String, _FileCoverage> files, bool showUntested) {
  if (files.isEmpty) {
    print('❌ No coverage data found');
    return;
  }

  // Sort by coverage (lowest first)
  final sortedFiles = files.values.toList()
    ..sort((a, b) => a.coverage.compareTo(b.coverage));

  final totalLines = sortedFiles.fold<int>(0, (sum, f) => sum + f.totalLines);
  final totalTested =
      sortedFiles.fold<int>(0, (sum, f) => sum + f.testedLines);
  final overallCoverage =
      totalLines == 0 ? 0.0 : (totalTested / totalLines) * 100;

  // Print header
  print('═' * 90);
  print('📈 OVERALL COVERAGE: ${_formatPercent(overallCoverage)} '
      '($totalTested/$totalLines lines)');
  print('═' * 90);
  print('');

  // Print per-file coverage
  for (final file in sortedFiles) {
    final icon = _getCoverageIcon(file.coverage);
    final bar = _getCoverageBar(file.coverage);

    print(
        '$icon ${_formatPercent(file.coverage).padRight(6)} $bar ${file.shortPath}');
    print('   ${file.testedLines}/${file.totalLines} lines tested');

    if (showUntested && file.unterstedLineNumbers.isNotEmpty) {
      final lines = file.unterstedLineNumbers
          .take(10)
          .map((n) => n.toString())
          .join(', ');
      final more = file.unterstedLineNumbers.length > 10
          ? ' ... and ${file.unterstedLineNumbers.length - 10} more'
          : '';
      print('   ❌ Untested lines: $lines$more');
    }

    print('');
  }

  // Summary stats
  print('═' * 90);
  print('📊 SUMMARY');
  print('═' * 90);

  final wellCovered =
      sortedFiles.where((f) => f.coverage >= 80).length;
  final partialCovered =
      sortedFiles.where((f) => f.coverage >= 50 && f.coverage < 80).length;
  final poorCovered = sortedFiles.where((f) => f.coverage < 50).length;

  print('  ✅ Well covered (80%+):     $wellCovered files');
  print('  ⚠️  Partial coverage (50-80%): $partialCovered files');
  print('  ❌ Poor coverage (<50%):     $poorCovered files');
  print('');
  print('Total files analyzed: ${files.length}');
  print('');

  if (showUntested) {
    print('💡 Use --untested to see untested line numbers for each file');
  } else {
    print('💡 Use: dart run tool/coverage_report.dart --untested');
    print('   To see untested line numbers for each file');
  }
  print('');
}

String _getCoverageIcon(double coverage) {
  if (coverage >= 80) return '✅';
  if (coverage >= 50) return '⚠️ ';
  return '❌';
}

String _getCoverageBar(double coverage) {
  final filled = (coverage / 10).round();
  final empty = 10 - filled;
  final bar = '█' * filled + '░' * empty;
  return '[$bar]';
}

String _formatPercent(double percent) => '${percent.toStringAsFixed(1)}%';
