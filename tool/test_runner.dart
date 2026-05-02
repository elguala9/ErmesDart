#!/usr/bin/env dart
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

/// Test runner that runs the full test suite.
void main(List<String> args) async {
  print('ErmesDart Test Runner');
  print('');

  // Run the tests
  print('Running tests...');
  print('');

  final testArgs = [
    'test',
    'packages/ermes_test/test/',
    ...args,
  ];

  final testProcess = await Process.start('dart', testArgs);

  // Forward stdout
  unawaited(testProcess.stdout
    .transform(SystemEncoding().decoder)
    .transform(const LineSplitter())
    .forEach((line) => print(line)));

  // Forward stderr
  unawaited(testProcess.stderr
    .transform(SystemEncoding().decoder)
    .transform(const LineSplitter())
    .forEach((line) => stderr.writeln(line)));

  final exitCode = await testProcess.exitCode;
  exit(exitCode);
}
