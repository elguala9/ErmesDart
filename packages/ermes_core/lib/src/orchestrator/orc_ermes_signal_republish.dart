import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';

import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connections.dart';
import 'orc_ermes_maintenance.dart';
import 'orc_ermes_passthrough.dart';
import 'orc_signal_republish_settings.dart';

/// Republishes our signal when the NAT mapping changes (RFC
/// ermes-signaling-nostr section 2): started by the first [openConnection],
/// stopped by [destroy].
///
/// The republisher publishes only on an endpoint change, so the key-rotation
/// republish (same endpoint, new key) never triggers a second publish; the
/// rotated key is read at each check and carried by the next one.
mixin OrcErmesSignalRepublish
    on
        OrcErmesCallbacks,
        OrcErmesPassthrough,
        OrcErmesConnections,
        OrcErmesMaintenance
    implements IOrcErmes<BookData> {
  /// Republisher configuration.
  @protected
  OrcSignalRepublishSettings get republishSettings;

  /// Local key pair, `null` without encryption.
  @protected
  IKeyExchange? get keyExchange;

  /// Whether encryption is on.
  @protected
  bool get encryptionEnabled;

  late final IErmesSignalRepublisher? _signalRepublisher =
      republishSettings.enabled
          ? ErmesSignalRepublisherFactory.create(
              ErmesSignalRepublisherInput(
                server: signalingServer,
                handler: signalingHandler,
                localPublicKey: () =>
                    encryptionEnabled ? keyExchange?.publicKey : null,
                minInterval: republishSettings.minInterval,
              ),
            )
          : null;

  bool _republisherStarted = false;

  @override
  Future<void> openConnection(
    IdPeer peer, {
    ISignalErmes? staticPeerSignal,
  }) async {
    if (!_republisherStarted) {
      _republisherStarted = true;
      _signalRepublisher?.start(republishSettings.checkInterval);
    }
    await super.openConnection(peer, staticPeerSignal: staticPeerSignal);
  }

  @override
  Future<void> destroy({bool force = false}) async {
    _signalRepublisher?.stop();
    await super.destroy(force: force);
  }
}
