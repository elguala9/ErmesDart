library;

/// Republishes our signal when the NAT mapping changes (RFC
/// ermes-signaling-nostr section 2).
abstract class IErmesSignalRepublisher {
  /// Rediscovers our public endpoint and publishes a fresh signal only when
  /// it differs from the last one published (the first call always
  /// publishes). Returns true when a signal was published. Changes seen
  /// within the minimum interval of the previous publish are deferred to
  /// the next call, so a flapping mapping cannot spam the relay.
  Future<bool> checkNow();

  /// Runs [checkNow] every [interval] until [stop] is called.
  void start(Duration interval);

  /// Stops the periodic check started by [start].
  void stop();
}
