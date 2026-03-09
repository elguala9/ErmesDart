import 'dart:io';

import 'package:stun/stun.dart';

/// Singleton for managing STUN handler instances
///
/// IStunHandler is used for STUN (Session Traversal Utilities for NAT)
/// protocol to handle NAT traversal for P2P connections.
class StunHandlerSingleton {
  /// Private constructor to prevent instantiation
  StunHandlerSingleton._();

  /// Singleton instance
  static StunHandlerSingleton? _instance;

  /// Default STUN server address
  static const String defaultStunServer = 'stun.l.google.com';

  /// Default STUN server port
  static const int defaultStunPort = 19302;

  /// Current STUN handler configuration
  late IStunHandler _handler;

  /// Gets the singleton instance, initializing with default configuration if needed
  static Future<StunHandlerSingleton> get instance async {
    if (_instance == null) {
      _instance = StunHandlerSingleton._();
      await _instance!._initializeDefault();
    }
    return _instance!;
  }

  /// Gets the current STUN handler
  IStunHandler get handler => _handler;

  /// Initialize with default configuration
  Future<void> _initializeDefault() async {
    final socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
    _handler = StunHandler(
      (
        address: defaultStunServer,
        port: defaultStunPort,
        socket: socket,
      ),
    );
  }

  /// Configure with custom STUN server
  Future<void> configure({
    String stunServer = defaultStunServer,
    int stunPort = defaultStunPort,
    bool ipv6 = true,
  }) async {
    final address =
        ipv6 ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4;
    final socket = await RawDatagramSocket.bind(address, 0);
    _handler = StunHandler(
      (
        address: stunServer,
        port: stunPort,
        socket: socket,
      ),
    );
  }

  /// Reset to singleton instance (for testing)
  static void reset() {
    _instance?._handler.close();
    _instance = null;
  }
}

/// Factory helper for creating IStunHandler instances (legacy - use StunHandlerSingleton instead)
///
/// IStunHandler is used for STUN (Session Traversal Utilities for NAT)
/// protocol to handle NAT traversal for P2P connections.
class StunHandlerFactoryHelper {
  /// Private constructor to prevent instantiation
  StunHandlerFactoryHelper._();

  /// Default STUN server address
  static const String defaultStunServer = 'stun.l.google.com';

  /// Default STUN server port
  static const int defaultStunPort = 19302;

  /// Creates a default IStunHandler instance
  ///
  /// Uses Google's public STUN server for NAT traversal.
  /// Binds to any available IPv4 address on a random port.
  ///
  /// Returns a new IStunHandler instance with default configuration
  static Future<IStunHandler> createDefault() async {
    final socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return StunHandler(
      (
        address: defaultStunServer,
        port: defaultStunPort,
        socket: socket,
      ),
    );
  }

  /// Creates an IStunHandler with custom STUN server
  ///
  /// [stunServer] The STUN server address (e.g., 'stun.l.google.com')
  /// [stunPort] The STUN server port (default: 19302)
  /// [ipv6] Use IPv6 instead of IPv4 (default: false)
  ///
  /// Returns a new IStunHandler instance with custom server
  static Future<IStunHandler> createWithServer({
    required String stunServer,
    int stunPort = defaultStunPort,
    bool ipv6 = false,
  }) async {
    final address =
        ipv6 ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4;
    final socket = await RawDatagramSocket.bind(address, 0);
    return StunHandler(
      (
        address: stunServer,
        port: stunPort,
        socket: socket,
      ),
    );
  }

  /// Creates an IStunHandler for RPC-based networks
  ///
  /// [rpcUrl] The RPC endpoint URL (e.g., 'http://localhost:9545')
  /// [stunServer] Optional custom STUN server (default: Google's)
  /// [stunPort] Optional custom STUN port (default: 19302)
  ///
  /// Returns a new IStunHandler instance
  static Future<IStunHandler> createWithRpc({
    required String rpcUrl,
    String stunServer = defaultStunServer,
    int stunPort = defaultStunPort,
  }) async {
    final socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return StunHandler(
      (
        address: stunServer,
        port: stunPort,
        socket: socket,
      ),
    );
  }

  /// Creates an IStunHandler with multiple STUN servers for redundancy
  ///
  /// Uses the first STUN server in the list.
  /// [stunServers] List of STUN server addresses (default: Google's)
  /// [stunPort] STUN server port (default: 19302)
  ///
  /// Returns a new IStunHandler instance configured with first server
  static Future<IStunHandler> createWithFallback({
    List<String> stunServers = const [defaultStunServer],
    int stunPort = defaultStunPort,
  }) async {
    final server =
        stunServers.isNotEmpty ? stunServers.first : defaultStunServer;
    final socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return StunHandler(
      (
        address: server,
        port: stunPort,
        socket: socket,
      ),
    );
  }

  /// Creates an IStunHandler for testing with loopback address
  ///
  /// Binds to loopback interface for isolated testing without network I/O.
  /// [stunServer] The STUN server address (default: localhost)
  /// [stunPort] The STUN server port (default: 19302)
  ///
  /// Returns a new IStunHandler instance for testing
  static Future<IStunHandler> createForTesting({
    String stunServer = 'localhost',
    int stunPort = defaultStunPort,
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    return StunHandler(
      (
        address: stunServer,
        port: stunPort,
        socket: socket,
      ),
    );
  }
}
