// ignore_for_file: avoid_print, avoid_classes_with_only_static_members
import 'dart:async';
import 'dart:io';

/// Helper to automatically manage Ganache lifecycle for tests
class GanacheManager {
  static const String ganacheRpcUrl = 'http://localhost:9545';
  static const Duration healthCheckTimeout = Duration(seconds: 2);
  static const Duration startupTimeout = Duration(seconds: 10);
  static const int maxRetries = 10;

  static bool _ganacheStartedByUs = false;
  static bool _initialized = false;

  /// Initialize Ganache - always restarts it fresh for a clean state.
  /// Returns true if Ganache is available after startup.
  static Future<bool> initialize() async {
    if (_initialized) {
      return _ganacheStartedByUs || await isAvailable();
    }

    _initialized = true;

    // Check if Docker is available
    if (!await _isDockerAvailable()) {
      print('⚠️  Docker is not available - Ganache tests will be skipped');
      return false;
    }

    // Always restart Ganache for a clean state
    print('🔄 Restarting Ganache for a clean state...');
    if (await _startGanache()) {
      print('✅ Ganache started successfully');
      _ganacheStartedByUs = true;
      return true;
    }

    print('⚠️  Failed to start Ganache - tests will be skipped');
    return false;
  }

  /// Returns the deployed SignalingContract address by reading docker logs.
  /// Falls back to the default address if docker logs are unavailable.
  static Future<String> getContractAddress() async {
    const fallback = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
    try {
      final process = await Process.run(
        'docker',
        ['logs', 'parresia-contract-deployer'],
      ).timeout(const Duration(seconds: 5));
      final output = process.stdout.toString() + process.stderr.toString();
      final match = RegExp(r'CONTRACT_ADDRESS=(0x[0-9a-fA-F]{40})').firstMatch(output);
      if (match != null) {
        return match.group(1)!;
      }
    } on Exception {
      // Ignore - return fallback
    }
    return fallback;
  }

  /// Check if Ganache is available (health check)
  static Future<bool> isAvailable() async {
    try {
      final process = await Process.run(
        'curl',
        [
          '-s',
          '-X',
          'POST',
          ganacheRpcUrl,
          '-H',
          'Content-Type: application/json',
          '-d',
          '{"jsonrpc":"2.0","method":"web3_clientVersion","id":1}',
        ],
      ).timeout(healthCheckTimeout);

      return process.exitCode == 0 &&
          process.stdout.toString().contains('jsonrpc');
    } on Exception {
      return false;
    }
  }

  /// Stop Ganache if we started it
  static Future<void> cleanup() async {
    if (_ganacheStartedByUs) {
      await _stopGanache();
      _ganacheStartedByUs = false;
      _initialized = false; // Reset for next initialize() to restart Ganache
    }
  }

  /// Internal: Check if Docker is available
  static Future<bool> _isDockerAvailable() async {
    try {
      // Try docker command
      final process = await Process.run(
        'docker',
        ['ps'],
      ).timeout(const Duration(seconds: 2));
      return process.exitCode == 0;
    } on Exception {
      // On Windows, try with full path
      try {
        final process = await Process.run(
          r'C:\Program Files\Docker\Docker\resources\bin\docker.exe',
          ['ps'],
        ).timeout(const Duration(seconds: 2));
        return process.exitCode == 0;
      } on Exception {
        return false;
      }
    }
  }

  /// Internal: Find project root (where .git exists)
  static Directory _findProjectRoot() {
    var current = Directory.current;

    // Search up to 10 levels for .git directory
    for (var i = 0; i < 10; i++) {
      if (File('${current.path}/.git').existsSync() ||
          Directory('${current.path}/.git').existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        // Reached filesystem root without finding .git
        break;
      }
      current = parent;
    }

    // Fallback: return current directory
    return Directory.current;
  }

  /// Internal: Start Ganache via docker-compose
  static Future<bool> _startGanache() async {
    try {
      // Find project root by looking for .git directory
      final projectDir = _findProjectRoot();
      final dockerComposeFile = File('${projectDir.path}/docker-compose-evm.yml');

      if (!dockerComposeFile.existsSync()) {
        print('⚠️  docker-compose-evm.yml not found');
        print('   Current dir: ${Directory.current.path}');
        print('   Project root: ${projectDir.path}');
        print('   Searched for: ${dockerComposeFile.path}');
        return false;
      }

      print('   Found docker-compose-evm.yml at: ${projectDir.path}');

      print('🚀 Starting Ganache via docker-compose...');

      // Clean up old containers/networks first
      print('   Cleaning up old containers...');
      try {
        await Process.run(
          'docker',
          ['compose', '-f', 'docker-compose-evm.yml',
            'down', '--remove-orphans'],
          workingDirectory: projectDir.path,
        ).timeout(const Duration(seconds: 15));
      } on Exception {
        // Ignore cleanup errors
      }

      // Force stop and remove old container if it still exists
      try {
        await Process.run(
          'docker',
          ['stop', 'parresia-contract-ganache'],
        ).timeout(const Duration(seconds: 5));
      } on Exception {
        // Ignore - container might not exist
      }

      try {
        await Process.run(
          'docker',
          ['rm', '-f', 'parresia-contract-ganache'],
        ).timeout(const Duration(seconds: 5));
      } on Exception {
        // Ignore - container might not exist
      }

      // Force remove old conflicting networks (if they exist)
      try {
        await Process.run(
          'docker',
          ['network', 'rm', 'parresia-contract-network'],
        ).timeout(const Duration(seconds: 5));
      } on Exception {
        // Ignore - network might not exist
      }

      // Wait a bit for port to be released
      await Future<void>.delayed(const Duration(seconds: 2));

      // Try standard docker-compose command
      ProcessResult process;
      try {
        process = await Process.run(
          'docker-compose',
          ['-f', 'docker-compose-evm.yml', 'up', '-d'],
          workingDirectory: projectDir.path,
        ).timeout(const Duration(seconds: 30));
      } on Exception {
        // Windows fallback: try docker compose (v2 syntax)
        print('   Trying docker compose (v2)...');
        process = await Process.run(
          'docker',
          ['compose', '-f', 'docker-compose-evm.yml', 'up', '-d'],
          workingDirectory: projectDir.path,
        ).timeout(const Duration(seconds: 30));
      }

      if (process.exitCode != 0) {
        print('Docker compose error: ${process.stderr}');
        return false;
      }

      // Wait for Ganache to be ready
      print('⏳ Waiting for Ganache to be ready...');
      for (var i = 0; i < maxRetries; i++) {
        if (await isAvailable()) {
          break;
        }
        if (i == maxRetries - 1) {
          print('⚠️  Timeout waiting for Ganache');
          return false;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      // Wait for the contract deployer to finish
      print('⏳ Waiting for contract deployer to finish...');
      for (var i = 0; i < 30; i++) {
        try {
          final statusResult = await Process.run(
            'docker',
            ['inspect', '--format', '{{.State.Status}}',
              'parresia-contract-deployer'],
          ).timeout(const Duration(seconds: 3));
          final status = statusResult.stdout.toString().trim();
          if (status == 'exited') {
            final exitResult = await Process.run(
              'docker',
              ['inspect', '--format', '{{.State.ExitCode}}',
                'parresia-contract-deployer'],
            ).timeout(const Duration(seconds: 3));
            final exitCode =
                int.tryParse(exitResult.stdout.toString().trim()) ?? -1;
            if (exitCode == 0) {
              print('✅ Contract deployed successfully');
              return true;
            }
            print('⚠️  Contract deployer failed (exit code $exitCode)');
            return false;
          }
        } on Exception {
          // ignore transient errors, keep polling
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      print('⚠️  Timeout waiting for contract deployer');
      return false;
    } on Exception catch (e) {
      print('Error starting Ganache: $e');
      return false;
    }
  }

  /// Internal: Stop Ganache via docker-compose
  static Future<void> _stopGanache() async {
    try {
      final projectDir = Directory.current;
      print('🛑 Stopping Ganache...');

      try {
        await Process.run(
          'docker-compose',
          ['-f', 'docker-compose-evm.yml', 'down'],
          workingDirectory: projectDir.path,
        ).timeout(const Duration(seconds: 10));
      } on Exception {
        // Windows fallback: try docker compose (v2 syntax)
        await Process.run(
          'docker',
          ['compose', '-f', 'docker-compose-evm.yml', 'down'],
          workingDirectory: projectDir.path,
        ).timeout(const Duration(seconds: 10));
      }

      print('✅ Ganache stopped');
    } on Exception catch (e) {
      print('⚠️  Warning: Failed to stop Ganache: $e');
    }
  }
}
