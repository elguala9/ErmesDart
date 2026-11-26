/// Default period of the NAT-mapping check run by [OrcErmes].
const Duration defaultSignalRepublishCheckInterval = Duration(seconds: 60);

/// Default minimum time between two republishes (flapping guard).
const Duration defaultSignalRepublishMinInterval = Duration(seconds: 30);

/// Configuration of the signal republisher started by `OrcErmes` (RFC
/// ermes-signaling-nostr section 2): our public endpoint is rediscovered
/// every [checkInterval] and a fresh signal is published only when it
/// changed, never twice within [minInterval].
class OrcSignalRepublishSettings {
  /// On by default with a 60 s check and a 30 s flapping guard.
  const OrcSignalRepublishSettings({
    this.enabled = true,
    this.checkInterval = defaultSignalRepublishCheckInterval,
    this.minInterval = defaultSignalRepublishMinInterval,
  });

  /// Settings that never start the republisher.
  const OrcSignalRepublishSettings.disabled()
    : enabled = false,
      checkInterval = defaultSignalRepublishCheckInterval,
      minInterval = defaultSignalRepublishMinInterval;

  /// Whether `OrcErmes` starts the republisher on its first open.
  final bool enabled;

  /// Period of the endpoint check.
  final Duration checkInterval;

  /// Minimum time between two publishes.
  final Duration minInterval;
}
