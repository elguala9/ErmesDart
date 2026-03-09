#!/usr/bin/env dart
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

/// Test runner that automatically starts Ganache before running tests
void main(List<String> args) async {
  print('🧪 ErmesDart Test Runner with Auto-Ganache Startup');
  print('');

  // Check if Ganache is already available
  final ganacheAvailable = await _isGanacheAvailable();
  var dockerAvailable = false;
  var ganacheStartedByUs = false;

  if (!ganacheAvailable) {
    print('❌ Ganache not available at http://localhost:9545');
    print('🚀 Attempting to start Ganache via docker-compose...');
    print('');

    dockerAvailable = await _isDockerAvailable();

    if (!dockerAvailable) {
      print('⚠️  Docker is not available or not running');
      print('');
      print('To enable ErmesSignalingServer tests, install Docker and run:');
      print('  docker-compose -f docker-compose-evm.yml up -d');
      print('');
      print('Continuing with other tests...');
      print('');
    } else {
      final started = await _startGanache();
      if (started) {
        print('✅ Ganache started successfully');
        ganacheStartedByUs = true;
        print('');
      } else {
        print('⚠️  Failed to start Ganache');
        print('Continuing with available tests...');
        print('');
      }
    }
  } else {
    print('✅ Ganache is already running');
    print('');
  }

  // Run the tests
  print('Running tests...');
  print('');

  final testProcess = await Process.start(
    'dart',
    ['test', 'packages/ermes_test/test/', ...args],
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await testProcess.exitCode;

  // Cleanup: optionally stop Ganache if we started it
  print('');
  print('Cleaning up...');

  if (ganacheStartedByUs) {
    print('🛑 Stopping Ganache...');
    await _stopGanache();
  }

  exit(exitCode);
}

/// Check if Ganache is available
Future<bool> _isGanacheAvailable() async {
  try {
    final process = await Process.run(
      'curl',
      [
        '-s',
        '-X',
        'POST',
        'http://localhost:9545',
        '-H',
        'Content-Type: application/json',
        '-d',
        '{"jsonrpc":"2.0","method":"web3_clientVersion","id":1}',
      ],
    ).timeout(const Duration(seconds: 2));

    return process.exitCode == 0 &&
        process.stdout.toString().contains('jsonrpc');
  } on Exception {
    return false;
  }
}

/// Check if Docker is available
Future<bool> _isDockerAvailable() async {
  try {
    final process = await Process.run(
      'docker',
      ['ps'],
    ).timeout(const Duration(seconds: 2));
    return process.exitCode == 0;
  } on Exception {
    return false;
  }
}

/// Start Ganache via docker-compose
Future<bool> _startGanache() async {
  try {
    final projectDir = Directory.current;
    final dockerComposeFile = File('${projectDir.path}/docker-compose-evm.yml');

    if (!dockerComposeFile.existsSync()) {
      print('⚠️  docker-compose-evm.yml not found');
      return false;
    }

    print('Starting docker-compose...');
    final process = await Process.run(
      'docker-compose',
      ['-f', 'docker-compose-evm.yml', 'up', '-d'],
      workingDirectory: projectDir.path,
    ).timeout(const Duration(seconds: 30));

    if (process.exitCode != 0) {
      print('Docker compose error: ${process.stderr}');
      return false;
    }

    // Wait for Ganache to be ready
    print('⏳ Waiting for Ganache to be ready...');
    for (var i = 0; i < 30; i++) {
      if (await _isGanacheAvailable()) {
        return true;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    print('⚠️  Timeout waiting for Ganache');
    return false;
  } on Exception catch (e) {
    print('Error starting Ganache: $e');
    return false;
  }
}

/// Stop Ganache via docker-compose
Future<void> _stopGanache() async {
  try {
    final projectDir = Directory.current;
    await Process.run(
      'docker-compose',
      ['-f', 'docker-compose-evm.yml', 'down'],
      workingDirectory: projectDir.path,
    ).timeout(const Duration(seconds: 10));
  } on Exception catch (e) {
    print('Warning: Failed to stop Ganache: $e');
  }
}
