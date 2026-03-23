import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../orc_ermes.dart';

/// Advanced factory for creating OrcErmes instances with pre-configured
/// components and various initialization scenarios.
///
/// This factory handles the creation of all OrcErmes dependencies using
/// [StunShspHandlerSingleton], which unifies STUN NAT traversal and SHSP
/// socket management into a single handler.
///
/// Use cases:
/// - Local testing (Ganache)
/// - Production with real blockchain network
/// - Custom configurations
class OrcErmesAdvancedFactory {
  /// Private constructor to prevent instantiation
  OrcErmesAdvancedFactory._();

  /// Returns the [StunShspHandlerSingleton], initializing it if needed.
  static Future<StunShspHandlerSingleton> _getHandler() async {
    final handler = StunShspHandlerSingleton.instance;
    if (!handler.isInitialized) {
      await handler.initialize();
    }
    return handler;
  }

  /// Creates OrcErmes with Ganache blockchain (local testing)
  ///
  /// Assumes:
  /// - Ganache running at http://localhost:9545
  /// - SignalingContract deployed and available
  /// - Account 0 is the current user
  ///
  /// [contract] The deployed SignalingContract instance
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance ready for local testing
  static Future<OrcErmes> createWithGanache({
    required SignalingContract contract,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async =>
      createWithContract(
        contract: contract,
        accountId: '0x0000000000000000000000000000000000000000',
        enableEncryption: enableEncryption,
        connectionTimeoutMs: connectionTimeoutMs,
      );

  /// Creates OrcErmes with specified blockchain contract
  ///
  /// Uses default STUN server (Google's) and auto-configured socket.
  ///
  /// [contract] The deployed SignalingContract instance
  /// [accountId] The account ID of the current user
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance with custom contract
  static Future<OrcErmes> createWithContract({
    required SignalingContract contract,
    required IdAccountType accountId,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async {
    final handler = await _getHandler();

    return OrcErmes.fromContract(
      contract: contract,
      accountId: accountId,
      stunShspHandler: handler,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }

  /// Creates OrcErmes with custom STUN server
  ///
  /// [contract] The SignalingContract
  /// [accountId] The account ID
  /// [stunServer] Custom STUN server address
  /// [stunPort] Custom STUN server port (default: 19302)
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance with custom STUN server
  static Future<OrcErmes> createWithCustomStun({
    required SignalingContract contract,
    required IdAccountType accountId,
    required String stunServer,
    int stunPort = 19302,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer(stunServer, stunPort);

    return OrcErmes.fromContract(
      contract: contract,
      accountId: accountId,
      stunShspHandler: handler,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }

  /// Creates OrcErmes with RPC endpoint configuration
  ///
  /// [contract] The SignalingContract
  /// [accountId] The account ID
  /// [rpcUrl] The RPC endpoint URL (e.g., 'http://localhost:9545')
  /// [stunServer] Optional custom STUN server (default: Google's)
  /// [stunPort] Optional custom STUN port (default: 19302)
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance configured for RPC
  static Future<OrcErmes> createWithRpc({
    required SignalingContract contract,
    required IdAccountType accountId,
    String rpcUrl = 'http://localhost:9545',
    String stunServer = 'stun.l.google.com',
    int stunPort = 19302,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer(stunServer, stunPort);

    return OrcErmes.fromContract(
      contract: contract,
      accountId: accountId,
      stunShspHandler: handler,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }

  /// Creates OrcErmes for testing
  ///
  /// Uses loopback addresses and local ports for isolated testing.
  ///
  /// [contract] The SignalingContract
  /// [accountId] The account ID
  /// [enableEncryption] Enable ECDH encryption (default: true)
  ///
  /// Returns a new OrcErmes instance configured for testing
  static Future<OrcErmes> createForTesting({
    required SignalingContract contract,
    required IdAccountType accountId,
    bool enableEncryption = true,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer('localhost', 19302);

    return OrcErmes.fromContract(
      contract: contract,
      accountId: accountId,
      stunShspHandler: handler,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: 5000,
    );
  }

  /// Creates OrcErmes with IPv6 support
  ///
  /// [contract] The SignalingContract
  /// [accountId] The account ID
  /// [stunServer] Optional custom STUN server (default: Google's)
  /// [stunPort] Optional custom STUN port (default: 19302)
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance with IPv6 support
  static Future<OrcErmes> createWithIPv6({
    required SignalingContract contract,
    required IdAccountType accountId,
    String stunServer = 'stun.l.google.com',
    int stunPort = 19302,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) async {
    final handler = await _getHandler();
    handler.setStunServer(stunServer, stunPort, ipv6: true);

    return OrcErmes.fromContract(
      contract: contract,
      accountId: accountId,
      stunShspHandler: handler,
      enableEncryption: enableEncryption,
      connectionTimeoutMs: connectionTimeoutMs,
    );
  }
}
