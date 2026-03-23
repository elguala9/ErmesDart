import 'package:stun_shsp/stun_shsp.dart';

/// Base class with SHSP socket access logic.
///
/// Delegates socket access to [StunShspHandlerSingleton].
/// Call [StunShspHandlerSingleton.initialize] before accessing sockets.
class ShspSocketHandler {
  ShspSocketHandler();

  /// Gets the IPv4 SHSP socket from [StunShspHandlerSingleton].
  IShspSocket get ipv4Socket =>
      StunShspHandlerSingleton.instance.ipv4ShspSocket;

  /// Gets the IPv6 SHSP socket from [StunShspHandlerSingleton] (may be null).
  IShspSocket? get ipv6Socket =>
      StunShspHandlerSingleton.instance.ipv6ShspSocket;

  /// Gets the underlying [StunShspHandlerSingleton].
  StunShspHandlerSingleton get stunShspHandler =>
      StunShspHandlerSingleton.instance;
}

/// Singleton accessor for SHSP sockets managed by [StunShspHandlerSingleton].
class ShspSocketHandlerSingleton extends ShspSocketHandler {
  ShspSocketHandlerSingleton._();

  static final ShspSocketHandlerSingleton _instance =
      ShspSocketHandlerSingleton._();

  static ShspSocketHandlerSingleton get instance => _instance;

  /// No-op: lifecycle is managed by [StunShspHandlerSingleton].
  static void reset() {}
}
