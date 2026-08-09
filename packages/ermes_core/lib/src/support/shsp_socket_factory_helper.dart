import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

/// Factory helper for creating IShspSocket instances
///
/// IShspSocket is the low-level transport socket used for communication.
/// It implements the SHSP (Single Hand Shake Protocol) for establishing
/// P2P connections with proper authentication and encryption handshakes.
class ShspSocketFactoryHelper {
  /// Private constructor to prevent instantiation
  ShspSocketFactoryHelper._();

  /// Creates a default IShspSocket instance
  ///
  /// Binds to any available IPv4 address on a random port.
  /// Uses UDP for low latency communication.
  ///
  /// Returns a new IShspSocket instance with default configuration
  static Future<IShspSocket> createDefault() async =>
      ShspSocket.bind(InternetAddress.anyIPv4, 0);

  /// Creates an IShspSocket with IPv6 support
  ///
  /// Binds to any available IPv6 address on a random port.
  ///
  /// Returns a new IShspSocket instance with IPv6
  static Future<IShspSocket> createIPv6() async =>
      ShspSocket.bind(InternetAddress.anyIPv6, 0);

  /// Creates an IShspSocket bound to a specific port
  ///
  /// [port] The port number to bind to (0 = auto-assign)
  /// [ipv6] Use IPv6 instead of IPv4 (default: false)
  ///
  /// Returns a new IShspSocket instance bound to specified port
  static Future<IShspSocket> createWithPort({
    required int port,
    bool ipv6 = false,
  }) async {
    final address = ipv6 ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4;
    return ShspSocket.bind(address, port);
  }

  /// Creates an IShspSocket with custom address
  ///
  /// [address] The network interface to bind to
  /// [port] The port number to bind to (0 = auto-assign)
  ///
  /// Returns a new IShspSocket instance with custom address
  static Future<IShspSocket> createWithAddress({
    required InternetAddress address,
    required int port,
  }) async =>
      ShspSocket.bind(address, port);

  /// Creates an IShspSocket for testing
  ///
  /// Binds to loopback interface for isolated testing without network I/O.
  /// Uses IPv4 loopback (127.0.0.1) on random port.
  ///
  /// Returns a new IShspSocket instance for testing
  static Future<IShspSocket> createForTesting() async =>
      ShspSocket.bind(InternetAddress.loopbackIPv4, 0);

  /// Creates an IShspSocket for testing with specific port
  ///
  /// Useful when you need a known port for testing.
  /// [port] The port number to bind to
  ///
  /// Returns a new IShspSocket instance for testing on specific port
  static Future<IShspSocket> createForTestingWithPort(int port) async =>
      ShspSocket.bind(InternetAddress.loopbackIPv4, port);
}
