import 'dart:async';
import 'dart:io';

/// Helper to automatically manage Ganache lifecycle for tests
class GanacheManager {
  static const String ganacheRpcUrl = 'http://localhost:9545';
  static const Duration healthCheckTimeout = Duration(seconds: 2);
  static const Duration startupTimeout = Duration(seconds: 30);
  static const int maxRetries = 30;

  static bool _ganacheStartedByUs = false;
  static bool _initialized = false;

  /// Initialize Ganache - starts it if not already running
  /// Returns true if Ganache is available (either was already running or we started it)
  static Future<bool> initialize() async {
    if (_initialized) {
      return _ganacheStartedByUs || await isAvailable();
    }

    _initialized = true;

    // Check if Ganache is already running
    if (await isAvailable()) {
      print('✅ Ganache is already running at $ganacheRpcUrl');
      return true;
    }

    print('❌ Ganache not available at $ganacheRpcUrl');

    // Check if Docker is available
    if (!await _isDockerAvailable()) {
      print('⚠️  Docker is not available - Ganache tests will be skipped');
      return false;
    }

    // Try to start Ganache
    if (await _startGanache()) {
      print('✅ Ganache started successfully');
      _ganacheStartedByUs = true;
      return true;
    }

    print('⚠️  Failed to start Ganache - tests will be skipped');
    return false;
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
    } catch (e) {
      return false;
    }
  }

  /// Stop Ganache if we started it
  static Future<void> cleanup() async {
    if (_ganacheStartedByUs) {
      await _stopGanache();
      _ganacheStartedByUs = false;
    }
  }

  /// Internal: Check if Docker is available
  static Future<bool> _isDockerAvailable() async {
    try {
      final process = await Process.run(
        'docker',
        ['ps'],
      ).timeout(const Duration(seconds: 2));
      return process.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Internal: Start Ganache via docker-compose
  static Future<bool> _startGanache() async {
    try {
      final projectDir = Directory.current;
      final dockerComposeFile = File('${projectDir.path}/docker-compose-evm.yml');

      if (!dockerComposeFile.existsSync()) {
        print('⚠️  docker-compose-evm.yml not found');
        return false;
      }

      print('🚀 Starting Ganache via docker-compose...');
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
      for (var i = 0; i < maxRetries; i++) {
        if (await isAvailable()) {
          return true;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      print('⚠️  Timeout waiting for Ganache');
      return false;
    } catch (e) {
      print('Error starting Ganache: $e');
      return false;
    }
  }

  /// Internal: Stop Ganache via docker-compose
  static Future<void> _stopGanache() async {
    try {
      final projectDir = Directory.current;
      print('🛑 Stopping Ganache...');
      await Process.run(
        'docker-compose',
        ['-f', 'docker-compose-evm.yml', 'down'],
        workingDirectory: projectDir.path,
      ).timeout(const Duration(seconds: 10));
      print('✅ Ganache stopped');
    } catch (e) {
      print('⚠️  Warning: Failed to stop Ganache: $e');
    }
  }
}
